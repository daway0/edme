from django_middleware_global_request.middleware import get_request
from rest_framework.views import APIView
from .models import (
    AppTeam,
    System,
    Permission,
    GroupUser,
    UserRoleGroupPermission,
    App,
    RelatedPermissionAPPURL,
    AppURL,
    PermissionGroup,
    Server,
)
from InternalAccess.models import AppInfo
from .serializers import (
    AppTeamSerializer,
    AllAppsInfoSerializer,
    AppUrlSerializer,
    SystemSerializer,
    AppBySystemCodeSerializer,
    AppByAppCodeSerializer,
    ServerSerializer,
    AppSerializer,
)
from rest_framework.response import Response
from rest_framework import status
from django.urls import reverse
import requests
from HR.utils import generate_auth_token
from HR.decorators import public_api, public_view
from django.utils.decorators import method_decorator
from Utility.Authentication.Helper import V1_get_username_is_valid_token,V1_generate_token,V1_get_username_ip_from_first_token
from shared_lib import core as slcore



class GetAppTeams(APIView):
    @method_decorator(public_api)
    def get(self, *args, **kwargs):
        app_label = kwargs.get('app_label')
        qs = AppTeam.objects.filter(AppCode__AppLabel=app_label)
        if qs:
            app_team_serializer = AppTeamSerializer(qs, many=True)
            return Response({'data': app_team_serializer.data}, status=status.HTTP_200_OK)
        return Response({'state': 'error'}, status=status.HTTP_400_BAD_REQUEST)



class GetAllAppsInfo(APIView):
    @method_decorator(public_api)
    def get(self, request, *args, **kwargs):
        qs = AppInfo.objects.all()
        if request.data.get('return-dict') == '1' or request.GET.get('return-dict') == '1' or request.POST.get(
                'return-dict') == '1' or kwargs.get('return-dict') == '1':
            tmp = {}
            for item in qs:
                _item = item.__dict__
                _item.pop('_state')
                _item.update({
                    'FullUrl': item.FullUrl
                })
                obj = {
                    str(item.AppName): _item
                }
                tmp.update(obj)
            return Response({'data': tmp}, status=status.HTTP_200_OK)
        else:
            if qs:
                all_apps_info_serializer = AllAppsInfoSerializer(qs, many=True)
                return Response({'data': all_apps_info_serializer.data}, status=status.HTTP_200_OK)



class CheckUserPermission(APIView):
    @method_decorator(public_view)
    def get(self, request, *args, **kwargs):
        url = request.scheme + "://" + request.get_host() + reverse('AccessControl:all_app_info')
        token = generate_auth_token(request)
        url += "?auth_token=" + token
        res_all_app_info = requests.get(url,headers={'Authorization':f'Bearer {generate_auth_token(request)}', "Service-Authorization":slcore.generate_token("e.rezaee")} )
        all_app_info = []
        if res_all_app_info.status_code == 200:
            all_app_info = res_all_app_info.json().get('data')
        permission_code = kwargs.get('permission_code')
        username = kwargs.get('username')
        state = "ok"
        HasPermission = False
        StatusCode = 403
        Message = ""
        if not Permission.objects.filter(Code=permission_code).exists():
            StatusCode = 400
            Message = "مجوز نامعتبر است"
        else:
            app_info = get_obj_with_key('AppName', 'HR', all_app_info)
            token = generate_auth_token(request)
            url = app_info.get('APPSCHEMA') + str(app_info.get('APPIP')) + ":" + str(
                app_info.get('APPPORT')) + "/HR/api/get-user/" + username + "/"

            res = requests.get(url,headers={'Authorization':f'Bearer {token}', "Service-Authorization":slcore.generate_token("e.rezaee")})
            if res.status_code != 200:
                StatusCode = 400
                Message = "کاربر نامعتبر است"
            else:
                # پیدا کردن گروه های کاربر
                UserGroups = GroupUser.objects.filter(User=username)

                if UserGroups:
                    for Group in UserGroups:
                        if UserRoleGroupPermission.objects.filter(PermissionCode__Code=permission_code,
                                                                  OwnerPermissionGroup__id=Group.Group.id).exists():
                            HasPermission = True
                            StatusCode = 200
                if StatusCode != 200:
                    token = generate_auth_token(request)
                    url = app_info.get('APPSCHEMA') + app_info.get('APPIP') + ":" + str(
                        app_info.get('APPPORT')) + f"/HR/api/get-user-roles/{request.user.UsereName}/"
                    url += "?auth_token=" + token
                    res = requests.get(url,headers={'Authorization':f'Bearer {generate_auth_token(request)}', "Service-Authorization":slcore.generate_token("e.rezaee")})
                    UserRoles = []
                    if res.status_code == 200:
                        UserRoles = res.json().get('data')
                    if UserRoles:
                        for Role in UserRoles:
                            if UserRoleGroupPermission.objects.filter(PermissionCode__Code=permission_code,
                                                                      OwnerPermissionRole=Role).exists():
                                HasPermission = True
                                StatusCode = 200
                if StatusCode != 200:
                    if UserRoleGroupPermission.objects.filter(PermissionCode__Code=permission_code,
                                                              OwnerPermissionUser=username).exists():
                        HasPermission = True
                        StatusCode = 200
                if StatusCode != 200:
                    Message = "دسترسی این کاربر مجاز نمی باشد"

        return Response({'data': HasPermission, "Message": Message, "state": state}, status=StatusCode)



class GetPermittedAllUrl(APIView):
    @method_decorator(public_api)
    def get(self, request, *args, **kwargs):
        token = generate_auth_token(request)
        username = kwargs.get('username')
        url = request.scheme + "://" + request.get_host() + reverse('AccessControl:all_app_info')
        url += "?auth_token=" + token
        res_all_app_info = requests.get(url,headers={'Authorization':f'Bearer {generate_auth_token(request)}', "Service-Authorization":slcore.generate_token("e.rezaee")})
        all_app_info = []
        if res_all_app_info.status_code == 200:
            all_app_info = res_all_app_info.json().get('data')

        UserGroup = list(GroupUser.objects.filter(User=username).values_list('Group_id', flat=True))
        UserPermissionGroup = list(
            UserRoleGroupPermission.objects.filter(OwnerPermissionGroup__in=UserGroup).values_list('PermissionCode',
                                                                                                   flat=True))
        app_info = get_obj_with_key('AppName', 'HR', all_app_info)
        res = requests.get(app_info.get('APPSCHEMA') + app_info.get('APPIP') + ":" + str(
            app_info.get('APPPORT')) + f"/HR/api/get-user-roles/{username}/",headers={'Authorization':f'Bearer {generate_auth_token(request)}', "Service-Authorization":slcore.generate_token("e.rezaee")})
        UserRole = []
        if res.status_code == 200:
            UserRole = res.json().get('data')
        UserPermissionRole = list(
            UserRoleGroupPermission.objects.filter(OwnerPermissionRole__in=UserRole).values_list('PermissionCode',
                                                                                                 flat=True))

        UserPermission = list(
            UserRoleGroupPermission.objects.filter(OwnerPermissionUser=username).values_list('PermissionCode',
                                                                                             flat=True))

        Permissions = UserPermissionGroup + UserPermissionRole + UserPermission

        AppPermission = list(
            Permission.objects.filter(PermissionType=Permission.PermissionType_Desktop,
                                      Code__in=Permissions).values_list('Code', flat=True))

        URlPermission = list(
            RelatedPermissionAPPURL.objects.filter(Permission__Code__in=AppPermission).values_list('AppURL__URL',
                                                                                                   flat=True))
        qs1 = AppURL.objects.filter(URL__in=URlPermission)
        qs2 = AppURL.objects.filter(IsPublic=True)
        qs = qs1.union(qs2)
        StatusCode = 200
        return Response({'data': {'rows': qs.values(), 'ids': qs.values_list('id', flat=True)}},
                        status=StatusCode)



class GetPermittedUrl(APIView):
    @method_decorator(public_api)
    def get(self, request, *args, **kwargs):
        app_label = kwargs.get('app_label')
        username = kwargs.get('username')
        url = request.scheme + "://" + request.get_host() + reverse('AccessControl:all_app_info')
        token = generate_auth_token(request)
        url += "?auth_token=" + token
        res_all_app_info = requests.get(url,headers={'Authorization':f'Bearer {generate_auth_token(request)}', "Service-Authorization":slcore.generate_token("e.rezaee")})
        all_app_info = []
        if res_all_app_info.status_code == 200:
            all_app_info = res_all_app_info.json().get('data')
        StatusCode = 403
        Message = ""
        HasPermission = False
        list_app_codes = App.objects.filter(AppLabel=app_label)
        app_code = list_app_codes.first().Code
        v = Validation(request)
        v.check_username(username)
        v.check_app_code(app_code)

        UserGroup = list(GroupUser.objects.filter(User=username).values_list('Group_id', flat=True))
        UserPermissionGroup = list(
            UserRoleGroupPermission.objects.filter(OwnerPermissionGroup__in=UserGroup).values_list('PermissionCode',
                                                                                                   flat=True))
        app_info = get_obj_with_key('AppName', 'HR', all_app_info)
        url = app_info.get('APPSCHEMA') + app_info.get('APPIP') + ":" + str(
            app_info.get('APPPORT')) + f"/HR/api/get-user-roles/{username}/"
        token = generate_auth_token(request)
        res = requests.get(url,headers={'Authorization':f'Bearer {token}', "Service-Authorization":slcore.generate_token("e.rezaee")})
        UserRole = []
        if res.status_code == 200:
            UserRole = res.json().get('data')
        UserPermissionRole = list(
            UserRoleGroupPermission.objects.filter(OwnerPermissionRole__in=UserRole).values_list('PermissionCode',
                                                                                                 flat=True))

        UserPermission = list(
            UserRoleGroupPermission.objects.filter(OwnerPermissionUser=username).values_list('PermissionCode',
                                                                                             flat=True))

        Permissions = UserPermissionGroup + UserPermissionRole + UserPermission

        AppPermission = list(
            Permission.objects.filter(PermissionType=Permission.PermissionType_Desktop,
                                      AppCode__Code__in=list(list_app_codes.values_list("Code", flat=True)),
                                      Code__in=Permissions).values_list('Code', flat=True))

        URlPermission = list(
            RelatedPermissionAPPURL.objects.filter(Permission__Code__in=AppPermission).values_list('AppURL__URL',
                                                                                                   flat=True))

        AppURLPermission = list(
            AppURL.objects.filter(AppCode__Code__in=list(list_app_codes.values_list("Code", flat=True)),
                                  URL__in=URlPermission).values_list('URL', flat=True))
        publiuc_url_permission = list(AppURL.objects.filter(IsPublic=True).values_list('URL', flat=True))

        AppURLPermission += publiuc_url_permission
        # if len(AppURLPermission) == 0 and app_code != "WFECTR":
        #     StatusCode = 403
        #     Message = "دسترسی این کاربر مجاز نمی باشد"
        #     return Response({'data': {'URL': AppURLPermission, "Message": Message, "HasPermission": False}},
        #                     status=StatusCode)
        StatusCode = 200
        return Response({'data': {'URL': AppURLPermission, "Message": Message,"HasPermission": True if len(AppURLPermission) > 0 else False}},status=StatusCode)



class CheckUserPermissionList(APIView):
    @method_decorator(public_api)
    def get(self, request, *args, **kwargs):
        app_label = kwargs.get('app_label')
        username = kwargs.get('username')
        url = request.scheme + "://" + request.get_host() + reverse('AccessControl:all_app_info')
        token = generate_auth_token(request)
        url += "?auth_token=" + token
        res_all_app_info = requests.get(url,headers={'Authorization':f'Bearer {generate_auth_token(request)}', "Service-Authorization":slcore.generate_token("e.rezaee")})
        all_app_info = []
        if res_all_app_info.status_code == 200:
            all_app_info = res_all_app_info.json().get('data')
        state = "ok"
        PermissionList = []
        StatusCode = 403
        Message = ""
        app_code = App.objects.filter(AppLabel=app_label).first().Code

        v = Validation(request)
        v.check_username(username)
        v.check_app_code(app_code)

        UserGroups = list(GroupUser.objects.filter(User=username).values_list('Group_id', flat=True))
        app_info = get_obj_with_key('AppName', 'HR', all_app_info)
        if UserGroups:
            StatusCode = 200
            PermissionList = list(
                UserRoleGroupPermission.objects.filter(OwnerPermissionGroup__in=UserGroups).values_list(
                    'PermissionCode__Code', flat=True))

            url = app_info.get('APPSCHEMA') + app_info.get('APPIP') + ":" + str(
                app_info.get('APPPORT')) + f"/HR/api/get-user-roles/{username}/"
            token = generate_auth_token(request)
            res = requests.get(url,headers={'Authorization':f'Bearer {token}', "Service-Authorization":slcore.generate_token("e.rezaee")})
            UserRoles = []
            if res.status_code == 200:
                UserRoles = res.json().get('data')

            if UserRoles:
                PermissionList = PermissionList + list(
                    UserRoleGroupPermission.objects.filter(OwnerPermissionRole__in=UserRoles).values_list(
                        'PermissionCode__Code', flat=True))
            PermissionList = PermissionList + list(
                UserRoleGroupPermission.objects.filter(OwnerPermissionUser=username).values_list('PermissionCode__Code',
                                                                                                 flat=True))

        return Response({'data': PermissionList, }, status=StatusCode)


class Validation():
    StatusCode = 406
    Message = ""

    def __init__(self, request):
        self.request = request

    def check_username(self, username):
        url = self.request.scheme + "://" + self.request.get_host() + reverse('AccessControl:all_app_info')
        request = get_request()
        token = generate_auth_token(request)
        url += "?auth_token=" + token
        res_all_app_info = requests.get(url,headers={'Authorization':f'Bearer {generate_auth_token(request)}', "Service-Authorization":slcore.generate_token("e.rezaee")})
        all_app_info = []
        if res_all_app_info.status_code == 200:
            all_app_info = res_all_app_info.json().get('data')
        app_info = get_obj_with_key('AppName', 'HR', all_app_info)
        uname = username
        url = app_info.get('APPSCHEMA') + app_info.get('APPIP') + ":" + str(
            app_info.get('APPPORT')) + f"/HR/api/get-user-roles/{uname}/"
        token = generate_auth_token(request)
        url += "?auth_token=" + token
        res = requests.get(url,headers={'Authorization':f'Bearer {generate_auth_token(request)}', "Service-Authorization":slcore.generate_token("e.rezaee")})
        if res.status_code != 200:
            StatusCode = 406
            Message = "نام کاربری معتبر نمی باشد"
            return Response({"Message": Message}, status=StatusCode)

    def check_app_code(self, app_code):
        if not (App.objects.filter(Code=app_code)).exists():
            StatusCode = 406
            Message = "کد برنامه معتبر نیست"
            return Response({"Message": Message}, status=StatusCode)

    def check_group(self, group_id):
        if not (PermissionGroup.objects.filter(PermissionGroup__id=group_id)).exists():
            StatusCode = 406
            Message = "گروه دسترسی معتبر نیست"
            return Response({"Message": Message}, status=StatusCode)

    def check_permission(self, permission_code):
        if not (Permission.objects.filter(Permission__Code=permission_code)).exists():
            StatusCode = 406
            Message = "دسترسی معتبر نیست"
            return Response({"Message": Message}, status=StatusCode)



class GetAppURL(APIView):
    @method_decorator(public_api)
    def get(self, *args, **kwargs):
        app_url_id = int(kwargs.get('app_url_id'))
        qs = AppURL.objects.filter(id=app_url_id).first()
        if qs:
            app_code_url_serializer = AppUrlSerializer(qs)
            return Response({'data': app_code_url_serializer.data}, status=status.HTTP_200_OK)

        return Response({'data': {'state': 'error'}}, status=status.HTTP_400_BAD_REQUEST)



class GetAllAppsURL(APIView):
    @method_decorator(public_api)
    def get(self, *args, **kwargs):
        qs = AppURL.objects.all().select_related("AppCode__SystemCode")
        if qs:
            app_url_serializer = AppUrlSerializer(qs, many=True)
            return Response({'data': app_url_serializer.data}, status=status.HTTP_200_OK)

        return Response({'data': {'state': 'error'}}, status=status.HTTP_400_BAD_REQUEST)



class GetSystem(APIView):
    @method_decorator(public_api)
    def get(self, *args, **kwargs):
        system_code = kwargs.get('system_code')
        qs = System.objects.filter(Code=system_code).first()
        if qs:
            system_serializer = SystemSerializer(qs)
            return Response({'data': system_serializer.data}, status=status.HTTP_200_OK)

        return Response({'data': {'state': 'error'}}, status=status.HTTP_400_BAD_REQUEST)



class GetAllSystems(APIView):
    @method_decorator(public_api)
    def get(self, *args, **kwargs):
        qs = System.objects.all()
        if qs:
            server_serializer = SystemSerializer(qs, many=True)
            return Response({'data': server_serializer.data}, status=status.HTTP_200_OK)
        return Response({'data': {'state': 'error'}}, status=status.HTTP_400_BAD_REQUEST)



class GetServer(APIView):
    @method_decorator(public_api)
    def get(self, *args, **kwargs):
        server_id = int(kwargs.get('server_id'))
        qs = Server.objects.filter(id=server_id).first()
        if qs:
            server_serializer = ServerSerializer(qs)
            return Response({'data': server_serializer.data}, status=status.HTTP_200_OK)

        return Response({'data': {'state': 'error'}}, status=status.HTTP_400_BAD_REQUEST)



class GetAllServers(APIView):
    @method_decorator(public_api)
    def get(self, *args, **kwargs):
        qs = Server.objects.all()
        if qs:
            server_serializer = ServerSerializer(qs, many=True)
            return Response({'data': server_serializer.data}, status=status.HTTP_200_OK)
        return Response({'data': {'state': 'error'}}, status=status.HTTP_400_BAD_REQUEST)



class GetAppBySystemCode(APIView):
    @method_decorator(public_api)
    def get(self, *args, **kwargs):
        system_code = kwargs.get('system_code')
        qs = App.objects.filter(SystemCode_id=system_code).first()
        if qs:
            app_serializer = AppBySystemCodeSerializer(qs)
            return Response({'data': app_serializer.data}, status=status.HTTP_200_OK)

        return Response({'data': {'state': 'error'}}, status=status.HTTP_400_BAD_REQUEST)



class GetAppByAppCode(APIView):
    @method_decorator(public_api)
    def get(self, *args, **kwargs):
        app_code = kwargs.get('app_code')
        qs = App.objects.filter(Code=app_code).first()
        if qs:
            app_serializer = AppByAppCodeSerializer(qs)
            return Response({'data': app_serializer.data}, status=status.HTTP_200_OK)

        return Response({'data': {'state': 'error'}}, status=status.HTTP_400_BAD_REQUEST)



class GetApps(APIView):
    @method_decorator(public_api)
    def get(self, *args, **kwargs):
        qs = App.objects.all()
        if qs:
            app_serializer = AppByAppCodeSerializer(qs, many=True)
            return Response({'data': app_serializer.data}, status=status.HTTP_200_OK)

        return Response({'data': {'state': 'error'}}, status=status.HTTP_400_BAD_REQUEST)



class GetAppByLabelSystem(APIView):
    @method_decorator(public_api)
    def get(self, request, *args, **kwargs):
        app_label = kwargs.get('app_label')
        system_code = kwargs.get('system_code')
        qs = App.objects.filter(AppLabel=app_label, SystemCode_id=system_code).first()
        if qs:
            current_serializer = AppSerializer(qs)
            return Response({'data': current_serializer.data}, status=status.HTTP_200_OK)
        return Response({'data': {'state': 'error'}}, status=status.HTTP_400_BAD_REQUEST)



class CheckUrlIsPublic(APIView):
    @method_decorator(public_api)
    def post(self, request, *args, **kwargs):
        return Response(status=501)


def get_obj_with_key(_key, _val, _list):
    ret = {}
    for item in _list:
        if _key in item:
            val = item.get(_key).lower()
            if val == _val.lower():
                ret = item
                break
    return ret


class GenerateToken(APIView):
    @method_decorator(public_api)
    def post(self, request, *args, **kwargs):
        first_token = request.data.get('first_token')
        user, user_ip = V1_get_username_ip_from_first_token(first_token)
        if user and user_ip:
            token = V1_generate_token(request, user, user_ip)
            return Response({'data': {'state': 'ok', 'token': token}}, status=200)
        return Response({'data': {'state': 'error'}}, status=200)


class CheckPermittedURL(APIView):
    @method_decorator(public_api)
    def post(self, request, *args, **kwargs):
        requested_url = request.data.get('URL')
        request_token = request.data.get('JWT')
        requested_ip = request.data.get('REQUESTED_IP')
        username = V1_get_username_is_valid_token(request_token, requested_ip)
        if username:
            url = request.scheme + "://" + request.get_host() + reverse('AccessControl:all_app_info')
            res_all_app_info = requests.get(url, headers={"Service-Authorization":slcore.generate_token("e.rezaee")})
            all_app_info = []
            if res_all_app_info.status_code == 200:
                all_app_info = res_all_app_info.json().get('data')

            UserGroup = list(GroupUser.objects.filter(User=username).values_list('Group_id', flat=True))
            UserPermissionGroup = list(
                UserRoleGroupPermission.objects.filter(OwnerPermissionGroup__in=UserGroup).values_list('PermissionCode',
                                                                                                       flat=True))
            app_info = get_obj_with_key('AppName', 'HR', all_app_info)
            res = requests.get(app_info.get('APPSCHEMA') + app_info.get('APPIP') + ":" + str(
                app_info.get('APPPORT')) + f"/HR/api/get-user-roles/{username}/", headers={"Service-Authorization":slcore.generate_token("e.rezaee")})
            UserRole = []
            if res.status_code == 200:
                UserRole = res.json().get('data')
            UserPermissionRole = list(
                UserRoleGroupPermission.objects.filter(OwnerPermissionRole__in=UserRole).values_list('PermissionCode',
                                                                                                     flat=True))

            UserPermission = list(
                UserRoleGroupPermission.objects.filter(OwnerPermissionUser=username).values_list('PermissionCode',
                                                                                                 flat=True))

            Permissions = UserPermissionGroup + UserPermissionRole + UserPermission

            AppPermission = list(
                Permission.objects.filter(PermissionType=Permission.PermissionType_Desktop,
                                          Code__in=Permissions).values_list('Code', flat=True))

            URlPermission = list(
                RelatedPermissionAPPURL.objects.filter(Permission__Code__in=AppPermission).values_list('AppURL__URL',
                                                                                                       flat=True))
            qs1 = AppURL.objects.filter(URL__in=URlPermission)
            qs2 = AppURL.objects.filter(IsPublic=True)
            qs = qs1.union(qs2)
            list_urls = qs.values_list('URL', flat=True)

            # list_all_data = list(qs.values())
            requested_url = str(str(requested_url.split("://")[1]).split(":")[1])
            requested_url = str(requested_url)[str(requested_url).find("/"):]
            if "/?" in requested_url:
                requested_url = requested_url[:str(requested_url).find("/?")+1]
            if requested_url[-1] != "/":
                requested_url += "/"

            if check_url_in_list(requested_url, list_urls):
                return Response({'data': {'state':'ok','access':True}},status=200)

        return Response({'data': {'state':'error','access':False}},status=200)


def check_url_in_list(requested_url,urls):
    return True
   