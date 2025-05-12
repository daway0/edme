import socket
import traceback
from django.shortcuts import render,redirect,reverse
import Systems.models as SystemsModel
from django.http import HttpResponseRedirect
import os
from Utility.Authentication.Utils import (
    V1_PermissionControl,
    V1_get_data_from_token,
    V1_find_token_from_request,
    V1_get_api_fetch_data,
    V1_update_url_params,
    V1_datetime_to_int,
    V1_jwt_enc
    )
import datetime,pytz
from Cartable.utils import get_all_active_users
from django.contrib.auth.models import User
from django.http.response import JsonResponse
import jwt
from django.views.decorators.csrf import csrf_exempt
from Utility.Authentication.Helper import V1_update_url_params

def RedirectToLoadSystem(request):
    url = reverse('Systems:Systems_view')
    if "token" in request.GET:
        url = V1_update_url_params(url,{'token':request.GET.get('token')})
    return redirect(url)

def find_app_from_all_apps(_dict,id):
    ret = None
    if _dict:
        for item in _dict:
            if item.get('id') and int(item.get('id')) == int(id):
                ret = item
                break
    return ret

def find_in_qs(_list,id):
    ret = None
    if _list:
        for item in _list:
            if int(item.id) == int(id):
                ret = item
                break
    return ret

def find_in_recursive(_list,id):
    qs = None
    for item in _list:
        if id is not None and int(item.id) == int(id):
            qs = item

    return qs


def find_all_childs(category_urls,categories):
    system_list = []
    cat_ids = []
    tmp = []
    dict_levels = {}
    for item in category_urls:
        a = 0
        if item.SystemCategory_id in tmp:
            continue
        tmp.append(item.SystemCategory_id)
        qs = categories.filter(id=item.SystemCategory_id).first()
        while qs:
            a+=1
            system_list.append(qs)
            cat_ids.append(qs.id)
            qs = categories.filter(id=qs.Parent_id).first()


    return system_list,cat_ids


def find_levels(SystemCategory):
    _d = {}
    categories = SystemsModel.SystemCategory.objects.all()

    for item in SystemCategory:
        if item.Parent_id is None:
            _d.update({str(item.id):0})

    for item in SystemCategory:
        if item.Parent_id is not None:
            parent_id = item.Parent_id
            level = 0
            while parent_id is not None:
                level += 1
                parent_id = categories.filter(id=parent_id).first().Parent_id
            _d.update({str(item.id):level})
    return _d

def get_http_host_ip(request):
    try:
        # one or both the following will work depending on your scenario
        socket.gethostbyname(socket.gethostname())
        return socket.gethostbyname(socket.getfqdn())
    except:
        return request.get_host().split(":")[0]


def check_and_set_cookie(request, response):
    token = V1_find_token_from_request(request)
    user_team_roles = V1_get_data_from_token(token, 'team_role_info')
    team = request.COOKIES.get('team')
    if team:
        if team not in [item.get('TeamCode') for item in user_team_roles]:
            response.set_cookie('team',user_team_roles[0].get('TeamCode'))
    else:
        response.set_cookie('team', user_team_roles[0].get('TeamCode'))
    return response


@V1_PermissionControl
def LoadSystems(request):
    if "eit-app" in request.get_host():
        schema = "https://" if request.is_secure() else "http://"
        cur_url = schema + request.get_host()  + request.path
        cur_url = cur_url.replace("eit-app",str(get_http_host_ip(request)))
        return HttpResponseRedirect(cur_url)
    # UserName = request.user.UserName
    # user_team_role = request.user.user_team_roles
    token = V1_find_token_from_request(request)
    UserName = V1_get_data_from_token(token, 'username')
    user_team_roles = V1_get_data_from_token(token, 'team_role_info')
    TeamCode = user_team_roles[0].get('TeamCode')
    TeamName = user_team_roles[0].get('TeamName')
    try:
        host = os.getenv('ACCESSCONTROL_ADDRESS_IP_PORT')
        all_user_urls = V1_get_api_fetch_data(f"{host}AccessControl/api/get-user-all-urls/{UserName}/")
        urls = all_user_urls.get('rows')
        ids = all_user_urls.get('ids')
        category_urls = SystemsModel.SystemCategoryURL.objects.filter(AppURL__in=ids)

        categories = SystemsModel.SystemCategory.objects.all()

        SystemCategory, cat_ids = find_all_childs(category_urls, categories)
        dict_levels = find_levels(SystemCategory)
        system_category_ids = SystemsModel.SystemCategoryURL.objects.filter(SystemCategory_id__in=cat_ids).values_list("SystemCategory_id",flat=True)#.values("AppURL","SystemCategory_id","SystemCategory__Title","SystemCategory__Icon","SystemCategory__Parent_id")


    except:
        traceback.print_exc()
        print("Access Control App is not running...")

    host = os.getenv('ACCESSCONTROL_ADDRESS_IP_PORT')
    all_apps_urls = V1_get_api_fetch_data(f"{host}AccessControl/api/get-all-apps-url/")
    all_apps = V1_get_api_fetch_data(f"{host}AccessControl/api/get-apps/")
    all_systems = V1_get_api_fetch_data(f"{host}AccessControl/api/get-all-systems/")
    all_servers = V1_get_api_fetch_data(f"{host}AccessControl/api/get-all-servers/")
    SystemList = []
    url = ''

    data = {
        "UserName": UserName,
        "TokenDate": V1_datetime_to_int(
            datetime.datetime.now(tz=pytz.timezone('Asia/Tehran'))),
        "exp": V1_datetime_to_int(
            datetime.datetime.now(tz=pytz.timezone('Asia/Tehran')) + datetime.timedelta(minutes=480))
    }
    access = jwt.encode(payload=data, key=os.getenv('JWT_AUTHENTICATE_SECRET_KEY_TEMPORARY'), algorithm="HS256")

    for s in SystemCategory:
        if s.id in system_category_ids:
            app_url_id = category_urls.filter(SystemCategory_id=s.id).first().AppURL # s.get('AppURL')
            for item in all_apps_urls:
                if int(item.get('id')) == int(app_url_id):
                    app_code = item.get('AppCode')
                    url = item.get('URL')
                    break

            for item in all_apps:
                if item.get('Code') == app_code:
                    system_code = item.get('SystemCode')
                    break

            for item in all_systems:
                if item.get('Code') == system_code:
                    system = item
                    server_id = item.get('Server')
                    break

            for item in all_servers:
                if int(item.get('id')) == int(server_id):
                    server = item

            server_id = system.get('Server')
            port_number = system.get('PortNumber')
            schema = "https://" if request.is_secure() else "http://"
            base_url = schema + server.get('IPAddress')
            filter_url = url if url.startswith("/") else '/' + url
            FullURL= base_url + ':' + str(port_number) + filter_url
            FullURL = FullURL.replace("192.168.50.15",get_http_host_ip(request))
            System = {
                'FullURL': FullURL,
                'Title': s.Title,
                'Parent': s.Parent_id,
                'HasURL': True,
                'id': s.id,
                'Icon': s.Icon,
                'Level': dict_levels.get(str(s.id)),
            }
        else:
            System = {
                'FullURL': '',
                'Title': s.Title,
                'Parent': s.Parent_id,
                'HasURL': False,
                'id': s.id,
                'Icon': s.Icon,
                'Level': dict_levels.get(str(s.id)),
            }

        SystemList.append(System)

    tmp_check = []
    tmp_SystemList = []
    for item in SystemList:
        if int(item.get('id')) not in tmp_check:
            tmp_check.append(int(item.get('id')))
            tmp_SystemList.append(item)
    SystemList = tmp_SystemList

    content ={
        'SystemList':SystemList,
        'access':access,
    }

    # active_users = list(UserTeamRole.objects.all().values_list("UserName",flat=True))
    active_users = get_all_active_users()
    list_teams = [item.get('TeamCode') for item in user_team_roles]
    list_teams = list(set(list_teams))
    # user_teams_rows = HR.models.Team.objects.filter(TeamCode__in=list_teams).values("TeamCode","TeamName")
    user_teams_rows = [{'TeamCode':item.get('TeamCode'),'TeamName':item.get('TeamName')} for item in user_team_roles]
    user_gender = V1_get_data_from_token(token,'user_Gender')
    user_full_name = V1_get_data_from_token(token,'user_FullName')
    content.update({'TeamName':TeamName,'TeamCode':TeamCode,'users':active_users,'team_cookie':request.COOKIES.get('team')})
    response = render(request, 'Portal/Systems.html', content)
    response = check_and_set_cookie(request, response)
    return response



@V1_PermissionControl
@csrf_exempt
def change_my_team(request):
    token = V1_find_token_from_request(request)
    user_team_roles = V1_get_data_from_token(token, 'team_role_info')
    #url = reverse('Systems:Systems_view')
    url = request.POST.get('next_url')
    url = V1_update_url_params(url,{'token':token})
    response = redirect(url)
    if request.method == "POST":
        selected_team = request.POST.get('selected_team')
        if selected_team in [item.get('TeamCode') for item in user_team_roles]:
            response.set_cookie('team',selected_team)

    return response

@V1_PermissionControl
@csrf_exempt
def generate_link_fake_user(request):
    if request.method == "POST":
        token = V1_find_token_from_request(request)
        action_username = V1_get_data_from_token(token, 'username')
        user = User.objects.filter(username=action_username).first()
        if user and user.is_superuser:
            change_to_username = request.POST.get('change_to_username')
            token = V1_jwt_enc({'username':change_to_username})
            next_url = request.POST.get('next_url')
            url = f"http://eit-app:5000/Auth/Fake/?next={next_url}&token={token}"
            return JsonResponse(data={'state':'ok','url':url},status=200)
        return JsonResponse(data={'state': 'error'}, status=500)
    return JsonResponse(data={'state':'error'},status=403)