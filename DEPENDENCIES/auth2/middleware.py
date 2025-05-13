import jwt
from django.conf import settings
from django.contrib import auth
from django.contrib.auth.backends import RemoteUserBackend
from django.contrib.auth import get_user_model
from django.contrib.auth.models import AnonymousUser
from django.http import HttpResponse
from django.contrib.auth.middleware import RemoteUserMiddleware
from django.core.exceptions import ImproperlyConfigured
from . import exceptions as ex

def extract_user_from_token(
        token,
        secret,
        algorithms,
        user_model,
        just_active_users=False
):
    """Extracts a user from a JWT token, raising exceptions on failure."""

    try:
        payload = jwt.decode(token, secret, algorithms=algorithms)
        username = payload.get("username")
        if not username:
            raise ex.MissingUsernameError()

        qs = user_model.objects.filter(username=username)
        if just_active_users:
            qs = qs.filter(is_active=True)
        user = qs.first()
        if not user:
            raise ex.InactiveUserError()

        return user

    except jwt.ExpiredSignatureError:
        raise ex.ExpiredTokenError()

    except jwt.InvalidTokenError:
        raise ex.InvalidTokenError()

    except Exception as e:
        raise ex.TokenDecodingError(f"Error decoding authorization token: {e}")

class CustomRemoteUserMiddlewareDEVMODE(RemoteUserMiddleware):
    def process_request(self, request):
        if not hasattr(settings, "DEV_USER"):
            raise AttributeError("Define DEV_USER for using CustomRemoteUserMiddlewareDEVMODE")
        auth_backend = auth.load_backend("django.contrib.auth.backends.RemoteUserBackend")
        user = auth_backend.authenticate(request=request, remote_user=settings.DEV_USER)
        if user:    
            request.user = user
            auth.login(request, user)
        else: 
            return HttpResponse("make sure DEV_USER record is defined in database", status=470)
        

class CustomRemoteUserMiddleware(RemoteUserMiddleware):
    """
    Extends Django’s RemoteUserMiddleware to support JWT-based service authentication
    and user impersonation. This middleware inspects incoming HTTP headers to determine
    the effective user for the request.

    Process Flow:
      1. **Preliminary Check:**
         - Ensure the AuthenticationMiddleware has been applied (i.e. request.user exists).

      2. **IIS Username Extraction:**
         - Attempt to retrieve the IIS-provided username from the REMOTE_USER header.
         - Clean the username (remove domain prefix, e.g., "EIT\\") and update the header.
         - If missing, continue without error.

      3. **Service Authentication via JWT:**
         - Look for a JWT token in the HTTP_SERVICE_AUTHORIZATION header.
         - If present, decode the token to extract the “actual” user (only active users are considered).
         - On token decoding errors, immediately return an HTTP error response.

      4. **User Impersonation via JWT:**
         - Look for a JWT token in the HTTP_IMPERSONATE_USERNAME header.
         - If present, decode the token to extract the impersonated user.
         - On token decoding errors, immediately return an HTTP error response.

      5. **Determining the Effective User:**
         - **If an impersonation token is provided:**
             a. If a user is already authenticated, log them out.
             b. Require that either a valid service token or an IIS username is available.
             c. If only an IIS username is present, fetch the corresponding active user from the database.
             d. Set `request.actual_user` to the “actual” user and override REMOTE_USER with the impersonated user’s username.

         - **Else if only a service token is provided:**
             a. Log out any pre-authenticated user.
             b. Set `request.actual_user` to the user obtained from the service token.
             c. Update REMOTE_USER to this user’s username.

         - **Else (no JWT tokens provided):**
             a. Leave REMOTE_USER as provided by IIS.
             b. `request.actual_user` remains unset until later.

      6. **Final Processing:**
         - Call the parent class’s `process_request` to complete standard remote user authentication.
         - If authentication fails (i.e. request.user is Anonymous), return an HTTP error response (status 470).
         - If no impersonation occurred, update `request.actual_user` to reflect the authenticated user.

    This middleware allows flexible authentication:
      - Direct service-to-service requests using JWT tokens.
      - Optional user impersonation when a valid impersonation token is provided.
      - Fallback to IIS-based authentication when no JWT tokens are present.
    """

    header = "REMOTE_USER"
    force_logout_if_no_header = True
    domain = "EIT\\"

    def clean_username(self, username, request):
        return username.replace(self.domain, "")

    def process_request(self, request):
        # Ensure that the AuthenticationMiddleware has already run.
        if not hasattr(request, "user"):
            raise ImproperlyConfigured(
                "The Django remote user auth middleware requires the "
                "authentication middleware to be installed. Edit your "
                "MIDDLEWARE setting to insert 'AuthenticationMiddleware' "
                "before the RemoteUserMiddleware class."
            )

        User = get_user_model()
        actual_user = None
        impersonation_user = None
        iis_user = None

        request.actual_user = None
        request.impersonated = False

        # --- Trying to get REMOTE_USER provided by IIS
        try:
            iis_user = self.clean_username(request.META[self.header], request)
            request.META[self.header] = iis_user # replace cleaned
        except KeyError:
            pass

        # --- Process Service Authorization header for the actual user ---
        service_token = request.META.get("HTTP_SERVICE_AUTHORIZATION")
        if service_token:
            try:
                actual_user = extract_user_from_token(
                    service_token,
                    settings.JWT_SECRET,
                    [getattr(settings, "JWT_ALGORITHM", "HS256")],
                    User,
                    just_active_users=True
                )
            except ex.CustomAuthError as e:
                return HttpResponse(e.message, status=e.status_code)


        # --- Process Impersonation header for impersonated user ---
        impersonation_token = request.META.get("HTTP_IMPERSONATE_USERNAME")
        if impersonation_token:
            try:
                impersonation_user = extract_user_from_token(
                    impersonation_token,
                    settings.JWT_SECRET,
                    [getattr(settings, "JWT_ALGORITHM", "HS256")],
                    User,
                )
            except ex.CustomAuthError as e:
                return HttpResponse(e.message, status=e.status_code)

        # --- Determine which user to set for authentication ---
        if impersonation_user:
            if hasattr(request, "user") and request.user.is_authenticated:
                auth.logout(request)

            if not (actual_user or iis_user):
                return HttpResponse(
                    status=ex.ImpersonateTokenOnlyIsNotSufficientError.status_code
                )

            elif not actual_user and iis_user:
                # manually filling actual user
                actual_user = User.objects.filter(
                    username=iis_user,
                    is_active=True).first()
                if not actual_user:
                    return HttpResponse(status=ex.InactiveUserError.status_code)


            request.impersonated = True
            request.actual_user = actual_user
            request.META[self.header] = impersonation_user.get_username()
        elif actual_user:
            # When an incoming request contains the Service-Authorization
            # header (not with impersonate-username), it means the request
            # is issued by a service. In this case, if the session
            # (i.e., the user is authenticated) or the REMOTE_USER is set,
            # they should be ignored.
            if hasattr(request, "user") and request.user.is_authenticated:
                auth.logout(request)

            request.actual_user = actual_user
            request.META[self.header] = actual_user.get_username()
        else:
            # No JWT tokens provided; leave REMOTE_USER as is
            # (typically provided by IIS).
            request.actual_user = None

        # --- Continue with the default RemoteUserMiddleware processing ---
        super().process_request(request)

        if isinstance(request.user, AnonymousUser):
            return HttpResponse(status=470)

        if not request.impersonated:
            request.actual_user = request.user
