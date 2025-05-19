from django.conf import settings


def my_variable(request):
    return {
        "MAIN_SERVER": settings.MAIN_SERVER,
        "MAIN_SERVER_NAME": settings.MAIN_SERVER_NAME,
        "HR_PORT": settings.HR_PORT,
        "EIT_PORT": settings.EIT_PORT,
        "PORTAL_PORT": settings.PORTAL_PORT,
        "PROCESSMANAGEMENT_PORT": settings.PROCESSMANAGEMENT_PORT,
        "NOTIFICATION_PORT": settings.NOTIFICATION_PORT,
    }
