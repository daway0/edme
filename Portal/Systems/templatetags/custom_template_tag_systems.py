from django import template
from django.contrib.auth.models import User
from Utility.Authentication.Helper import V1_get_api_fetch_data,V1_get_host_from_server
register = template.Library()

@register.filter(name='get_user_profile_img')
def get_user_profile_img(username):
    if username:
        return "/media_hr/HR/PersonalPhoto/"+username.replace("@eit","") + ".jpg"
    return ''


@register.filter(name='check_is_superuser')
def check_is_superuser(username):
    ret = False
    user = User.objects.filter(username=username).first()
    if user and user.is_superuser:
        ret = True
    return ret


@register.filter(name='get_all_users')
def get_all_users(request):
    url = V1_get_host_from_server() + ":14000/HR/api/all-users/"
    users = V1_get_api_fetch_data(url)
    return users


@register.filter(name='remove_duplicate_team')
def remove_duplicate_team(teams):
    _tmp = []
    _return_teams = []
    for item in teams:
        if item.get('TeamCode') not in _tmp:
            _tmp.append(item.get('TeamCode'))
            _return_teams.append(item)

    return _return_teams
