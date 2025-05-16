import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
PARENT_DIR = str(BASE_DIR.parent).replace("\\", "\\\\")
DEBUG = True	
SECRET_KEY = "django-insecure-#kkatg$g5w^93x$r8a@2bo*c8scivp8&k0it4_bvjw4197b1go"
JWT_SECRET = SECRET_KEY


ALLOWED_HOSTS = ["127.0.0.1", "eit-app", "192.168.20.81"]

INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    # apps
    "HR.apps.HrConfig",
    # 3rd party
    "rest_framework",
    "corsheaders",
    "auth2",
    "whitenoise"
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "whitenoise.middleware.WhiteNoiseMiddleware",
    "corsheaders.middleware.CorsMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    # "auth2.middleware.CustomRemoteUserMiddleware",
    "auth2.middleware.CustomRemoteUserMiddlewareDEVMODE",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

AUTH_USER_MODEL = "auth2.User"
AUTHENTICATION_BACKENDS = ['django.contrib.auth.backends.RemoteUserBackend']
# DEV_USER = "e.rezaee"
DEV_USER = "m.sepahkar"
# DEV_USER = "m.khakvar"



ROOT_URLCONF = "Config.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [os.path.join(BASE_DIR, "templates")],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.debug",
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

WSGI_APPLICATION = "Config.wsgi.application"


# Database
# https://docs.djangoproject.com/en/3.2/ref/settings/#databases

DATABASES = {
    "default": {
        "ENGINE": "mssql",  # 'mssql',
        "NAME": "HR",
        "USER": "sa",
        "PASSWORD": "Master123",
        "HOST": "EIT-DJANGO-DB\\DJANGODB",
        "PORT": "",
        "OPTIONS": {
            "driver": "ODBC Driver 17 for SQL Server",  # 'SQL Server Native Client 11.0'
        },
    }
}


# Password validation
# https://docs.djangoproject.com/en/3.2/ref/settings/#auth-password-validators

AUTH_PASSWORD_VALIDATORS = [
    {
        "NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.MinimumLengthValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.CommonPasswordValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.NumericPasswordValidator",
    },
]


# Internationalization
# https://docs.djangoproject.com/en/3.2/topics/i18n/

LANGUAGE_CODE = "fa-ir"

TIME_ZONE = "Asia/Tehran"

USE_I18N = True

USE_L10N = True

USE_TZ = True


# this section append end of every settings.py

STATIC_URL = "/static/"
if DEBUG:
    STATICFILES_DIRS = [os.path.join(BASE_DIR, "static")]
else:
    STATIC_ROOT = os.path.join(BASE_DIR, "static")
MEDIA_URL = "/media/"
MEDIA_ROOT = os.path.join(BASE_DIR, "media")
STATIC_URL_EIT = "/static_eit/"
STATIC_ROOT_EIT = os.path.join(BASE_DIR.parent, "EIT\static")
MEDIA_URL_HR = "/media_hr/"
MEDIA_ROOT_HR = os.path.join(BASE_DIR.parent, "HR\media")


DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"


SESSION_COOKIE_NAME = os.getcwd().split("\\")[-1] + "_sessionid"

DATA_UPLOAD_MAX_NUMBER_FIELDS = 10240
CORS_ALLOW_ALL_ORIGINS = True

MAIN_SERVER = "192.168.20.81"
HR_PORT = "14000"
EIT_PORT = "17000"
PORTAL_PORT = "23000"