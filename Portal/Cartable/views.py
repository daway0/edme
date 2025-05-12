import datetime
import json
from django.shortcuts import render,reverse
from .models import DocumentFlow,Document
import traceback
from django.shortcuts import render,redirect,reverse, get_list_or_404
import Systems.models as SystemsModel
from django.views.decorators.csrf import csrf_exempt
from django.contrib.auth import logout
from django.http.response import JsonResponse
import socket
from django.http import StreamingHttpResponse
import os
from Utility.Authentication.Utils import (
    V1_PermissionControl,
    V1_get_data_from_token,
    V1_find_token_from_request,
    V1_datetime_to_int,
    V1_get_api_fetch_data,
    V1_get_host_from_server,
    V1_get_access_control_ip_port
)
from .utils import get_all_active_users
import pytz
import jwt


def get_current_server_ip():
    socket.gethostbyname(socket.gethostname())
    ip = socket.gethostbyname(socket.getfqdn())
    return ip


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
def my_cartable(request):
    token = V1_find_token_from_request(request)
    username = V1_get_data_from_token(token, 'username')
    user_team_roles = V1_get_data_from_token(token, 'team_role_info')
    context = {}
    #host = os.getenv('ACCESSCONTROL_ADDRESS_IP_PORT')
    all_apps_urls = V1_get_api_fetch_data(f"{V1_get_access_control_ip_port()}AccessControl/api/get-all-apps-url/")
    all_users = V1_get_api_fetch_data(f"{V1_get_host_from_server()}:14000/HR/api/all-users/")
    all_users = {str(item.get('UserName')).lower():item for item in all_users}
    inbox = DocumentFlow.objects.filter(InboxOwner=username, IsVisible=True).order_by('-ReceiveDate')
    #outbox = DocumentFlow.objects.filter(SenderUser=username).order_by('-SendDate')
    outbox = DocumentFlow.objects.filter(SenderUser=username).order_by('-id')
    my_document = Document.objects.filter(DocumentOwner=username).values_list('id')
    mybox = DocumentFlow.objects.filter(DocumentId__in=my_document).order_by('-ReceiveDate')
    active_users = get_all_active_users()
    if active_users:
        active_users = [item.get('UserName') for item in active_users if item.get('UserName')]

    data = {
        "UserName": username,
        "TokenDate": V1_datetime_to_int(
            datetime.datetime.now(tz=pytz.timezone('Asia/Tehran'))),
        "exp": V1_datetime_to_int(
            datetime.datetime.now(tz=pytz.timezone('Asia/Tehran')) + datetime.timedelta(minutes=480))
    }
    access = jwt.encode(payload=data, key=os.getenv('JWT_AUTHENTICATE_SECRET_KEY_TEMPORARY'), algorithm="HS256")

    all_apps = V1_get_api_fetch_data(f"{V1_get_access_control_ip_port()}AccessControl/api/get-all-apps-info/?return-dict=1")
    prefix_url_get_timed_email = all_apps.get('ProcessManagement').get('FullUrl')
    user_teams_rows = [{'TeamCode':item.get('TeamCode'),'TeamName':item.get('TeamName')} for item in user_team_roles] if user_team_roles else []
    context.update({'access':access,'users':active_users,'server_ip':get_current_server_ip(),'all_apps_urls':all_apps_urls,'user_teams_rows':user_teams_rows})
    context.update({'rows':inbox,'sender_rows':outbox,'my_cartable_rows':mybox ,'prefix_url_get_timed_email':prefix_url_get_timed_email,'all_users':all_users,'all_users_json':json.dumps(all_users)})
    response = render(request,'Cartable/my_cartable.html',context=context)
    response = check_and_set_cookie(request, response)
    return response


@csrf_exempt
def my_cartable_ajax(request):
    activeid = request.GET.get('activeid')
    token = V1_find_token_from_request(request)
    username = V1_get_data_from_token(token, 'username')
    data = {
        "UserName": username,
        "TokenDate": V1_datetime_to_int(
            datetime.datetime.now(tz=pytz.timezone('Asia/Tehran'))),
        "exp": V1_datetime_to_int(
            datetime.datetime.now(tz=pytz.timezone('Asia/Tehran')) + datetime.timedelta(minutes=480))
    }
    access = jwt.encode(payload=data, key=os.getenv('JWT_AUTHENTICATE_SECRET_KEY_TEMPORARY'), algorithm="HS256")
    host = os.getenv('ACCESSCONTROL_ADDRESS_IP_PORT')
    all_apps_urls = V1_get_api_fetch_data(f"{host}AccessControl/api/get-all-apps-url/")
    context = {'activeid':activeid,'server_ip':get_current_server_ip(),'all_apps_urls':all_apps_urls}
    # this is for inbox cartable
    inbox = DocumentFlow.objects.filter(InboxOwner=username,IsVisible=True).order_by('-ReceiveDate')
    #outbox = DocumentFlow.objects.filter(SenderUser=username).order_by('-SendDate')
    outbox = DocumentFlow.objects.filter(SenderUser=username).order_by('-id')
    my_document = Document.objects.filter(DocumentOwner=username).values_list('id')
    mybox = DocumentFlow.objects.filter(DocumentId__in=my_document).order_by('-ReceiveDate')
    context.update({'access':access,'rows':inbox,'sender_rows':outbox,'my_cartable_rows':mybox})
    return render(request,'Cartable/my_cartable_ajax.html',context=context)



def doc_flow_sse(request):
    #username = request.user.UserName
    token = V1_find_token_from_request(request)
    username = V1_get_data_from_token(token, 'username')
    def event_stream():
        rows = list(DocumentFlow.objects.filter(InboxOwner=username, SendDate__isnull=True,IsVisible=True).order_by('-id'))
        sender_rows = list(DocumentFlow.objects.filter(InboxOwner=username, SendDate__isnull=False,IsVisible=True).order_by('-id'))
        my_cartable_rows = list(DocumentFlow.objects.filter(SenderUser=username, PreviousFlow_id__isnull=True,IsVisible=True).order_by('-id'))
        return "data: {'rows':"+str(rows)+",'sender_rows':"+str(sender_rows)+",'my_cartable_rows':"+str(my_cartable_rows)+"} \n\n"

    return StreamingHttpResponse(event_stream(), content_type='text/event-stream')





def find_app_from_all_apps(_dict,id):
    ret = None
    for item in _dict:
        if int(item.get('id')) == int(id):
            ret = item
            break
    return ret


def GetPermittedSystemlist(request,username):

    SystemCategory = SystemsModel.SystemCategory.objects.all()
    systemlist = []
    host = os.getenv('ACCESSCONTROL_ADDRESS_IP_PORT')
    all_apps_url = V1_get_api_fetch_data(f"{host}AccessControl/api/get-all-apps-url/")
    for s in SystemCategory:
        if s.HasURL:
            try:
                RelatedURL = SystemsModel.SystemCategoryURL.objects.filter(SystemCategory_id=s.id).first()
                app_url_id = RelatedURL.AppURL
                #app_url = call_api(request, "AccessControl", "get-app-url", app_url_id)
                app_url = find_app_from_all_apps(all_apps_url,app_url_id)
                if app_url is None:
                    continue
                app_code = app_url.get('AppCode')
                app = V1_get_api_fetch_data(f"{host}AccessControl/api/get-app-by-appcode/{app_code}/")
                AppLabel = app.get('AppLabel')
                data = V1_get_api_fetch_data(f"{host}AccessControl/api/get-user-urls/{AppLabel}/{username}/")
                haspermission=data.get('HasPermission')
                if haspermission:
                    systemlist.append(s)
                    ParentId = s.Parent_id
                    ParentExist = SystemsModel.SystemCategory.objects.filter(id=ParentId).count()
                    while ParentExist > 0:
                        QS = SystemsModel.SystemCategory.objects.get(id=ParentId)
                        ParentId = QS.Parent_id
                        ParentExist = SystemsModel.SystemCategory.objects.filter(id=ParentId).count()
                        systemlist.append(QS)
            except:
                pass
                traceback.print_exc()
    return systemlist


def LoadSystems(request):
    #UserName = request.user.UserName
    token = V1_find_token_from_request(request)
    UserName = V1_get_data_from_token(token, 'username')
    #user_team_role = request.user.user_team_roles
    user_team_roles = V1_get_data_from_token(token, 'team_role_info')
    TeamCode = user_team_roles[0].get('TeamCode')
    try:
        SystemCategory=GetPermittedSystemlist(request,UserName)
    except:
        traceback.print_exc()
        print("Access Control App is not running...")
    SystemList = []
    for s in SystemCategory:
        FullURL=''
        if s.HasURL:
            FullURL=s.RelatedURL
            FullURL = FullURL.replace("192.168.50.15","192.168.20.81")
            FullURL = FullURL.replace('@TeamCode','')
            FullURL = FullURL.replace('@UserName', '')
            FullURL = FullURL.replace('@username', '')
            tmp = FullURL.split("/")
            tmp = [item for item in tmp if item]
            FullURL = "/".join(tmp)
            FullURL += '/?team='+TeamCode
        System = {
                'FullURL':FullURL,'Title':s.Title,'Parent':s.Parent_id
                ,'HasURL':s.HasURL,'id':s.id,'Icon':s.Icon,'Level':s.Level
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
    }

    # active_users = list(UserTeamRole.objects.all().values_list("UserName",flat=True))
    active_users = get_all_active_users()
    content.update({'users':active_users})
    response = render(request, 'Portal/Systems.html', content)
    #response = create_cookie_on_response(request,response)
    return response


def refresh_logout(request):
    logout(request)
    response = redirect(reverse('AuthUser:auth_detect'))
    response.delete_cookie(key='access')
    response.delete_cookie(key=os.getcwd().split("\\")[-1] + '_sessionid')
    return response


@csrf_exempt
def exit_from_cartable(request, id):
    token = V1_find_token_from_request(request)
    UserName = V1_get_data_from_token(token, 'username')
    #GenderTitlePrefixFullName = V1_get_data_from_token(token, 'user_GenderTitlePrefixFullName')
    doc_flow = DocumentFlow.objects.filter(id=id,InboxOwner=UserName).first()
    #host = os.getenv('ACCESSCONTROL_ADDRESS_IP_PORT')
    if doc_flow:
        # res = V1_get_api_fetch_data(f"{host}ProcessManagement/WorkflowEngine/api/get-process/{doc_flow.DocumentId.AppDocId}/{doc_flow.DocumentId.AppCode}/")
        # if res and "state" in res and res.get('state') == "ok":
        #     if "updated_before" in res:
        #         return JsonResponse({'state': 'ok','updated_before':1}, status=200)
        #     if "not_change_this" in res:
        #         return JsonResponse({'state': 'ok', 'not_change_this': 1}, status=200)
        #     doc = Document.objects.get(id=doc_flow.DocumentId_id)
        #     if "خروج از کارتابل" in doc.DocState:
        #         return JsonResponse({'state': 'ok', 'updated_before': 1}, status=200)
        # new_state = doc.DocState + "\r\n" + "(خروج از کارتابل توسط"
        # new_state += " "
        # new_state += GenderTitlePrefixFullName
        # new_state += " )"
        # doc.DocState = new_state
        # doc.save()
        #doc_flow.IsRead = True
        #doc_flow.SendDate = datetime.datetime.now()
        if doc_flow.IsVisible is True:
            doc_flow.IsVisible = False
            doc_flow.save()
            return JsonResponse({'state':'ok','updated_before':0},status=200)
        elif doc_flow.IsVisible is False:
            return JsonResponse({'state': 'ok', 'updated_before': 0,'not_change_this':1}, status=200)

    return JsonResponse({'state':'error'},status=400)

#
# def translate_user(request):
#     if request.method =="POST" and request.user.is_superuser:
#         new_user = create_not_exists_user(request.POST.get('to_user'))
#         if new_user:
#             login(request,new_user)
#             response = redirect(reverse('AuthUser:auth_detect'))
#             response = create_cookie_on_response(request,response)
#             return response
#
#     return redirect(reverse('AuthUser:auth_detect'))

@V1_PermissionControl
def workflow_visual(request, doc_id):
    return render(request, "Cartable/WorkFlow.html",context={"doc_id": doc_id})

