from django.urls import path, include


urlpatterns = [
    path("HR/", include("HR.urls")),
    path("RoleManager/", include("roleManager.urls")),
]
