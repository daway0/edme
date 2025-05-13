import datetime
from unittest.mock import MagicMock

from django.test import TestCase, RequestFactory
from django.contrib.auth import get_user_model
from django.conf import settings
from django.contrib import auth
from django.contrib.auth.models import AnonymousUser
from django.http import HttpResponse

import jwt

from .middleware import CustomRemoteUserMiddleware
from .models import EmptyUserTeamRole

User = get_user_model()

class UserTeamManagerTests(TestCase):
    def setUp(self):
        """Set up test users and team roles."""
        # Create manager users
        self.manager1 = User.objects.create_user(username="manager1", national_id="1001")
        self.manager2 = User.objects.create_user(username="manager2", national_id="1002")
        self.manager3 = User.objects.create_user(username="manager3", national_id="1003")

        # Create a normal user with team roles
        self.user = User.objects.create_user(
            username="employee", national_id="2001",
            team_roles=[
                {"TeamCode": "A", "ManagerNationalCode": "1001"},
                {"TeamCode": "B", "ManagerNationalCode": "1002"},
                {"TeamCode": "A", "ManagerNationalCode": "1003"},
            ]
        )

    def test_team_manager_without_team_roles_raises_exception(self):
        """Test that calling team_manager on a user with no team roles raises an exception."""
        user_without_team_roles = User.objects.create_user(username="no_roles", national_id="3001")
        with self.assertRaises(EmptyUserTeamRole):
            user_without_team_roles.team_manager()

    def test_team_manager_returns_all_managers(self):
        """Test that team_manager returns all managers for a user with multiple roles."""
        managers = self.user.team_manager()
        self.assertQuerysetEqual(
            managers.order_by("national_id"),  # Order for consistency
            User.objects.filter(national_id__in=["1001", "1002", "1003"]).order_by("national_id"),
            transform=lambda x: x  # Compare actual objects
        )

    def test_team_manager_with_teamcode(self):
        """Test that team_manager returns only managers of a specific team."""
        managers = self.user.team_manager(teamcode="A")
        self.assertQuerysetEqual(
            managers.order_by("national_id"),
            User.objects.filter(national_id__in=["1001", "1003"]).order_by("national_id"),
            transform=lambda x: x
        )

    def test_team_manager_with_invalid_teamcode(self):
        """Test that team_manager returns an empty QuerySet if no roles match the given team code."""
        managers = self.user.team_manager(teamcode="C")  # Team "C" doesn't exist
        self.assertFalse(managers.exists())  # Should be empty

    def test_team_manager_avoids_duplicate_managers(self):
        """Test that duplicate manager entries for the same team are not returned multiple times."""
        user_with_duplicates = User.objects.create_user(
            username="multi_role_user", national_id="3002",
            team_roles=[
                {"TeamCode": "A", "ManagerNationalCode": "1001"},
                {"TeamCode": "A", "ManagerNationalCode": "1001"},  # Duplicate manager
                {"TeamCode": "B", "ManagerNationalCode": "1002"},
            ]
        )

        managers = user_with_duplicates.team_manager()
        
        # Should return only two unique managers (1001 and 1002)
        self.assertQuerysetEqual(
            managers.order_by("national_id"),
            User.objects.filter(national_id__in=["1001", "1002"]).order_by("national_id"),
            transform=lambda x: x
        )


class CustomRemoteUserMiddlewareMassiveTests(TestCase):
    def setUp(self):
        self.factory = RequestFactory()
        # Create a dummy get_response callable
        self.middleware = CustomRemoteUserMiddleware(
            get_response=lambda r: None)
        self.User = get_user_model()

        # Create test users.
        self.user_actual = self.User.objects.create_user(
            username="actualuser", password="password", is_active=True)
        self.user_impersonated = self.User.objects.create_user(
            username="impersonateduser", password="password", is_active=True)
        self.user_inactive = self.User.objects.create_user(
            username="inactiveuser", password="password", is_active=False)
        self.user_random = self.User.objects.create_user(
            username="random", password="password")

    def generate_token(self, username, expire_seconds=3600):
        payload = {
            "username": username,
            "exp": datetime.datetime.utcnow() + datetime.timedelta(
                seconds=expire_seconds)
        }
        token = jwt.encode(payload, settings.JWT_SECRET,
                           algorithm=getattr(settings, "JWT_ALGORITHM",
                                             "HS256"))
        # PyJWT >= 2.0 returns a string.
        return token if isinstance(token, str) else token.decode("utf-8")

    def patch_authenticate(self, expected_remote_user, return_user):
        """
        Patch auth.authenticate so that if the remote_user equals expected_remote_user,
        it returns return_user.
        """
        original_authenticate = auth.authenticate
        auth.authenticate = lambda request, remote_user: return_user if remote_user == expected_remote_user else None
        return original_authenticate

    def test_no_tokens_no_iis(self):
        """
        No tokens provided, No Cookie and no IIS REMOTE_USER header.
        Expect: No token branch executed, so request.actual_user remains None and
        after super().process_request the user is still anonymous => blocked response.


        """
        request = self.factory.get('/')
        # No REMOTE_USER in META.
        request.user = AnonymousUser()
        request.session = MagicMock()

        result = self.middleware.process_request(request)

        # Since no tokens and no IIS header, super() should not authenticate => blocked.
        self.assertIsInstance(request.user, AnonymousUser)
        self.assertIsNone(request.actual_user)
        self.assertIsInstance(result, HttpResponse)
        self.assertEqual(result.status_code, 470)

    def test_cookie_only(self):
        """
        No tokens provided and no IIS REMOTE_USER header just cookie.
        Expect: No token branch executed, so request.actual_user remains None and
        after super().process_request the user is still anonymous => blocked response.

        The cookie-only scenario might occur when a user tries to access an IIS
        unprotected endpoint (i.e., the incoming request does not have
        REMOTE_USER). In this case, the app must reject the request. Calling
        a non-protected IIS endpoint must include at least a Service-Authorization
        token.
        """
        request = self.factory.get('/')
        # No REMOTE_USER in META.
        request.user = self.user_actual
        request.session = MagicMock()

        result = self.middleware.process_request(request)

        # Since no tokens and no IIS header, super() should not authenticate => blocked.
        self.assertIsInstance(request.user, AnonymousUser)
        self.assertIsNone(request.actual_user)
        self.assertIsInstance(result, HttpResponse)
        self.assertEqual(result.status_code, 470)

    def test_iis_only(self):
        """
        Only IIS-provided REMOTE_USER header is present (no tokens).
        Expect: Fallback to IIS behavior.
        We simulate that the authentication backend returns self.user_actual.
        """
        request = self.factory.get('/')
        # Provide IIS header with domain prefix.
        request.META["REMOTE_USER"] = "EIT\\actualuser"
        request.user = AnonymousUser()
        request.session = MagicMock()

        # Patch authenticate to return user_actual when remote_user equals "actualuser".
        original_authenticate = self.patch_authenticate("actualuser",
                                                        self.user_actual)

        # Process the request.
        result = self.middleware.process_request(request)

        self.assertIsNone(result)
        self.assertEqual(request.user, self.user_actual)
        self.assertEqual(request.actual_user, self.user_actual)

        auth.authenticate = original_authenticate

    def test_iis_with_cookie(self):
        """
        In most cases, users access the app via this approach, and it totally
        handled by RemoteUserMiddleware.
        Expect: Fallback to IIS behavior.

        Notice: If the authentication provided by the cookie does not match the
        REMOTE_USER value in IIS, the RemoteUserMiddleware will prioritize the
        REMOTE_USER value.
        """
        request = self.factory.get('/')
        # Provide IIS header with domain prefix.
        request.META["REMOTE_USER"] = "EIT\\actualuser"
        request.user = self.user_actual

        request.session = MagicMock()

        # Patch authenticate to return user_actual when remote_user equals "actualuser".
        original_authenticate = self.patch_authenticate("actualuser",
                                                        self.user_actual)

        # Process the request.
        result = self.middleware.process_request(request)

        self.assertIsNone(result)
        self.assertEqual(request.user, self.user_actual)
        self.assertEqual(request.actual_user, self.user_actual)

        auth.authenticate = original_authenticate

    def test_service_only(self):
        """
        Only a valid Service-Authorization token is provided (no impersonation).
        Expect: The middleware should extract the actual user and use it.
        """
        request = self.factory.get('/')

        request.user = AnonymousUser()
        request.session = MagicMock()

        # Provide Service-Authorization token for actualuser.
        token_service = self.generate_token("actualuser")
        request.META["HTTP_SERVICE_AUTHORIZATION"] = token_service

        # Patch authenticate: when REMOTE_USER is set to "actualuser", return user_actual.
        original_authenticate = self.patch_authenticate("actualuser",
                                                        self.user_actual)

        self.middleware.process_request(request)

        self.assertEqual(request.actual_user, self.user_actual)
        self.assertEqual(request.user, self.user_actual)

        auth.authenticate = original_authenticate

    def test_service_with_cookie(self):
        """
        A valid Service-Authorization token and a valid cookie are provided
        (no impersonation)
        Expect: The middleware should ignore cookie and extract the actual
        user and use it.
        """
        request = self.factory.get('/')

        request.user = self.user_random
        request.session = MagicMock()

        token_service = self.generate_token("actualuser")
        request.META["HTTP_SERVICE_AUTHORIZATION"] = token_service

        original_authenticate = self.patch_authenticate(
            "actualuser",
            self.user_actual
        )

        self.middleware.process_request(request)

        self.assertEqual(request.actual_user, self.user_actual)
        self.assertEqual(request.user, self.user_actual)

        auth.authenticate = original_authenticate

    def test_remote_user_with_service_token(self):
        """
        If both REMOTE_USER and a valid Service-Authorization token are provided,
        (which is rare in normal cases) the middleware should use the
        Service-Authorization token and ignore REMOTE_USER.The user from the
        service token should be used for authentication.
        """
        request = self.factory.get('/')
        # Provide IIS header with domain (it should be ignored).
        request.META["REMOTE_USER"] = "EIT\\actualuser"
        request.user = AnonymousUser()
        request.session = MagicMock()

        token_service = self.generate_token("actualuser")
        request.META["HTTP_SERVICE_AUTHORIZATION"] = token_service

        original_authenticate = self.patch_authenticate("actualuser",
                                                        self.user_actual)

        self.middleware.process_request(request)

        self.assertEqual(request.actual_user, self.user_actual)
        self.assertEqual(request.user, self.user_actual)

        auth.authenticate = original_authenticate

    def test_remote_user_with_service_token_with_cookie(self):
        """
        If REMOTE_USER and a valid Service-Authorization token and also cookie
        are provided, (which is rare in normal cases) the middleware should use
        the Service-Authorization token and ignore both REMOTE_USER and cookie.
        The user from the service token should be used for authentication.
        """
        request = self.factory.get('/')
        # Provide IIS header with domain (it should be ignored).
        request.META["REMOTE_USER"] = "EIT\\actualuser"
        request.user = self.user_actual
        request.session = MagicMock()

        token_service = self.generate_token("actualuser")
        request.META["HTTP_SERVICE_AUTHORIZATION"] = token_service

        original_authenticate = self.patch_authenticate("actualuser",
                                                        self.user_actual)

        self.middleware.process_request(request)

        self.assertEqual(request.actual_user, self.user_actual)
        self.assertEqual(request.user, self.user_actual)

        auth.authenticate = original_authenticate

    def test_impersonation_only(self):
        """
        Only an impersonation token is provided (no Service-Authorization token).
        Expect: Branch condition (if impersonation_user exists but actual_user is missing)
        triggers a blocked response (401 Unauthorized).
        """
        request = self.factory.get('/')
        request.user = AnonymousUser()
        request.session = MagicMock()

        token_impersonation = self.generate_token("impersonateduser")
        request.META["HTTP_IMPERSONATE_USERNAME"] = token_impersonation

        result = self.middleware.process_request(request)

        self.assertIsInstance(result, HttpResponse)
        self.assertEqual(result.status_code, 452)
        self.assertIsNone(request.actual_user)
        self.assertIsInstance(request.user, AnonymousUser)
        self.assertFalse(request.impersonated)

    def test_impersonation_with_cookie(self):
        """
        An impersonation token and cookie are provided (no Service-Authorization token).
        Expect: Cookie ignored, Branch condition (if impersonation_user exists
        but actual_user is missing) triggers a blocked response (401 Unauthorized).
        """
        request = self.factory.get('/')
        request.user = self.user_random
        request.session = MagicMock()

        token_impersonation = self.generate_token("impersonateduser")
        request.META["HTTP_IMPERSONATE_USERNAME"] = token_impersonation

        result = self.middleware.process_request(request)

        self.assertIsInstance(result, HttpResponse)
        self.assertEqual(result.status_code, 452)
        self.assertIsNone(request.actual_user)
        self.assertIsInstance(request.user, AnonymousUser)

    def test_service_and_impersonation(self):
        """
        Both Service-Authorization and Impersonate-Username tokens are provided,
        and there is no IIS REMOTE_USER header.
        Expect: The middleware sets request.actual_user to the actual user extracted from
        Service-Authorization, and sets the impersonated user into request.user.
        """
        request = self.factory.get('/')
        request.user = AnonymousUser()
        request.session = MagicMock()

        token_service = self.generate_token("actualuser")
        token_impersonation = self.generate_token("impersonateduser")
        request.META["HTTP_SERVICE_AUTHORIZATION"] = token_service
        request.META["HTTP_IMPERSONATE_USERNAME"] = token_impersonation

        original_authenticate = self.patch_authenticate("impersonateduser",
                                                        self.user_impersonated)

        self.middleware.process_request(request)

        self.assertEqual(request.actual_user, self.user_actual)
        self.assertEqual(request.user, self.user_impersonated)
        self.assertTrue(request.impersonated)

        auth.authenticate = original_authenticate

    def test_service_and_impersonation_with_cookie(self):
        """
        Service-Authorization, Impersonate-Username tokens and cookie are provided,
        and there is no IIS REMOTE_USER header.
        Expect: Cookie will be ignored, The middleware sets request.actual_user
        to the actual user extracted from Service-Authorization, and sets the
        impersonated user into request.user.
        """
        request = self.factory.get('/')
        request.user = self.user_random
        request.session = MagicMock()

        token_service = self.generate_token("actualuser")
        token_impersonation = self.generate_token("impersonateduser")
        request.META["HTTP_SERVICE_AUTHORIZATION"] = token_service
        request.META["HTTP_IMPERSONATE_USERNAME"] = token_impersonation

        original_authenticate = self.patch_authenticate("impersonateduser",
                                                        self.user_impersonated)

        self.middleware.process_request(request)

        self.assertEqual(request.actual_user, self.user_actual)
        self.assertEqual(request.user, self.user_impersonated)
        self.assertTrue(request.impersonated)

        auth.authenticate = original_authenticate

    def test_remote_user_with_impersonation_token(self):
        """
        If both REMOTE_USER and an Impersonate-Username token are provided,
        the middleware should authenticate using the REMOTE_USER and impersonate the user
        from the impersonation token.
        The actual user should be stored in request.actual_user.
        """
        request = self.factory.get('/')

        request.META["REMOTE_USER"] = "EIT\\actualuser"
        request.user = AnonymousUser()
        request.session = MagicMock()

        token_impersonation = self.generate_token("impersonateduser")
        request.META["HTTP_IMPERSONATE_USERNAME"] = token_impersonation

        original_authenticate = self.patch_authenticate("impersonateduser",
                                                        self.user_impersonated)

        result = self.middleware.process_request(request)

        self.assertIsNone(result)
        self.assertEqual(request.actual_user, self.user_actual)
        self.assertEqual(request.user, self.user_impersonated)
        self.assertTrue(request.impersonated)

        auth.authenticate = original_authenticate

    def test_remote_user_with_impersonation_token(self):
        """
        If REMOTE_USER, an Impersonate-Username token and cookie are provided,
        cookie will be ignored
        """
        request = self.factory.get('/')

        request.META["REMOTE_USER"] = "EIT\\actualuser"
        request.user = self.user_random
        request.session = MagicMock()

        token_impersonation = self.generate_token("impersonateduser")
        request.META["HTTP_IMPERSONATE_USERNAME"] = token_impersonation

        original_authenticate = self.patch_authenticate("impersonateduser",
                                                        self.user_impersonated)

        result = self.middleware.process_request(request)

        self.assertIsNone(result)
        self.assertEqual(request.actual_user, self.user_actual)
        self.assertEqual(request.user, self.user_impersonated)
        self.assertTrue(request.impersonated)

        auth.authenticate = original_authenticate

    def test_remote_user_with_impersonation_token_with_service_token(self):
        """
        It’s impossible, but if it occurs, REMOTE_USER will be ignored, and
        the code will behave as if it only has Impersonate-Username and
        Service-Authorization (priority matters)
        """
        request = self.factory.get('/')

        request.META["REMOTE_USER"] = "EIT\\actualuser"
        request.user = AnonymousUser()
        request.session = MagicMock()

        token_service = self.generate_token("actualuser")
        token_impersonation = self.generate_token("impersonateduser")
        request.META["HTTP_SERVICE_AUTHORIZATION"] = token_service
        request.META["HTTP_IMPERSONATE_USERNAME"] = token_impersonation

        original_authenticate = self.patch_authenticate("impersonateduser",
                                                        self.user_impersonated)

        self.middleware.process_request(request)

        self.assertEqual(request.actual_user, self.user_actual)
        self.assertEqual(request.user, self.user_impersonated)
        self.assertTrue(request.impersonated)

        auth.authenticate = original_authenticate

    def test_remote_user_with_impersonation_token_with_service_token_with_cookie(
            self):
        """
        It’s impossible also :), but if it occurs, REMOTE_USER and cookie will
        be ignored, and the code will behave as if it only has Impersonate-Username
        and Service-Authorization (priority matters)
        """
        request = self.factory.get('/')

        request.META["REMOTE_USER"] = "EIT\\actualuser"
        request.user = self.user_random
        request.session = MagicMock()

        token_service = self.generate_token("actualuser")
        token_impersonation = self.generate_token("impersonateduser")
        request.META["HTTP_SERVICE_AUTHORIZATION"] = token_service
        request.META["HTTP_IMPERSONATE_USERNAME"] = token_impersonation

        original_authenticate = self.patch_authenticate("impersonateduser",
                                                        self.user_impersonated)

        self.middleware.process_request(request)

        self.assertEqual(request.actual_user, self.user_actual)
        self.assertEqual(request.user, self.user_impersonated)
        self.assertTrue(request.impersonated)

        auth.authenticate = original_authenticate

    def test_invalid_service_token(self):
        """
        If an invalid Service-Authorization token is provided,
        expect that the middleware returns an error response with the proper status.
        """
        request = self.factory.get('/')
        request.META["REMOTE_USER"] = "EIT\\actualuser"
        request.user = AnonymousUser()
        request.session = MagicMock()

        # Provide an invalid Service-Authorization token.
        request.META["HTTP_SERVICE_AUTHORIZATION"] = "invalid.token.value"

        result = self.middleware.process_request(request)

        self.assertIsInstance(result, HttpResponse)
        self.assertEqual(result.status_code, 441)

    def test_invalid_impersonation_token(self):
        """
        If an invalid Impersonate-Username token is provided,
        expect that the middleware returns an error response with the proper status.
        """
        request = self.factory.get('/')
        request.META["REMOTE_USER"] = "EIT\\actualuser"
        request.user = AnonymousUser()
        request.session = MagicMock()

        # Provide a valid Service-Authorization token for actualuser.
        token_service = self.generate_token("actualuser")
        request.META["HTTP_SERVICE_AUTHORIZATION"] = token_service
        # Provide an invalid impersonation token.
        request.META["HTTP_IMPERSONATE_USERNAME"] = "invalid.token.value"

        result = self.middleware.process_request(request)
        self.assertIsInstance(result, HttpResponse)
        # Based on our extract_user_from_token logic, an invalid impersonation token yields status 441.
        self.assertEqual(result.status_code, 441)





