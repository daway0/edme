import json
import traceback

from django.core.cache import cache
from django.db.models import Q
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView

from EIT.models import (
    Corp,
    Task as TaskModel,
    EIT_View_Verion,
    Feature,
    EIT_View_Feature_Team,
    CorpVersion,
)
from EIT.serializers import CorpSerializer, EITViewVerionSerializer, \
    TaskSerializer


class GetCorp(APIView):
    def get(self,request,*args,**kwargs):
        qs = Corp.objects.filter(ActiveInService=True)
        serializer = CorpSerializer(qs,many=True)
        return Response({'data':serializer.data }, status=status.HTTP_200_OK)


class GetTaskByIds(APIView):
    def get(self,request,*args,**kwargs):
        ids = request.data.get('ids')
        ActualWorkHours = list(Task.objects.filter(Id__in=ids).values_list('ActualWorkHours', flat=True))
        return Response({'data':ActualWorkHours }, status=status.HTTP_200_OK)


class GetTaskByIdsRetId(APIView):
    def get(self,request,*args,**kwargs):
        taskids = request.data.getlist('taskids')
        data = list(Task.objects.filter(Id__in=taskids).values_list("Id", flat=True))
        return Response({'data':data }, status=status.HTTP_200_OK)


class GetAllEitViewVersion(APIView):
    def get(self,request,*args,**kwargs):
        qs = EIT_View_Verion.objects.all()
        serializer_data = EITViewVerionSerializer(qs, many=True)
        data = serializer_data.data
        if "show_as_list" in request.GET or "show-as-list" in request.GET:
            data = list(qs.values_list("VersionNumber",flat=True))
        return Response({'data':data }, status=status.HTTP_200_OK)


class FindCorp(APIView):
    def get(self,request,*args,**kwargs):
        if request.data:
            qs = Corp.objects.filter(**request.data).first()
            serializer = CorpSerializer(qs)
            data = serializer.data
        else:
            qs = Corp.objects.all()
            if "return_dict" in request.GET or "return-dict" in request.GET:
                data = {item.get('CorpCode'):item for item in qs.values()}
            else:
                serializer = CorpSerializer(qs, many=True)
                data = serializer.data
        return Response({'data':data }, status=status.HTTP_200_OK)


class GetAllFeatures(APIView):
    def get(self, request, *args, **kwargs):
        key = "all_features"
        try:
            if key in cache:
                data = json.loads(cache.get(key))
            else:
                data = list(Feature.objects.all().values())
                cache.set(key, json.dumps(data,ensure_ascii=False))
            if "return_dict" in request.GET or "return-dict" in request.GET:
                data = {item.get('Code'):item for item in data}
        except:
            traceback.print_exc()

        return Response({'data': data}, status=200)


class GetFeatures(APIView):
    def post(self, request, *args, **kwargs):
        try:
            searched = request.data.get('searchTerm')
            if searched and len(searched) > 2:
                qs = Feature.objects.filter(FullTitle__isnull=False).filter(
                    Q(FullTitle__contains=searched) | Q(Code__contains=searched))[:50]
                data = [{'id': item.Code, 'text': item.FullTitle + " (" + str(item.Code) + ")"} for item in qs]
            else:
                data = [{'id': '-0', 'text': ''}]
            data = json.dumps(data)
            return Response({'data': data}, status=200)
        except:
            return Response({'state':'error'}, status=400)


class GetFeatureTitle(APIView):
    def post(self, request, *args, **kwargs):
        try:
            data = ''
            code = request.data.get('code')
            if code and len(code) > 0:
                qs = Feature.objects.filter(Code=int(code)).first()
                if qs:
                    data = qs.FullTitle + " (" + str(qs.Code) + ")"
            return Response({"state": "ok", 'data': data}, status=200)
        except:
            return Response({'state': "error"}, status=400)


class GetViewFeatureTeam(APIView):
    def get(self, request, *args, **kwargs):
        try:
            if request.data:
                qs = EIT_View_Feature_Team.objects.filter(TeamCode__in=request.data.get('teams'))
            else:
                qs = EIT_View_Feature_Team.objects.all()
            data = list(qs.values())
            return Response({"state": "ok", 'data': data}, status=200)
        except:
            return Response({"state": "error"}, status=400)


class GetAllCorpVersions(APIView):
    def get(self, request, *args, **kwargs):
        try:
            values_list = [item.name for item in CorpVersion._meta.fields]
            values_list.append("CorpCode__CorpName")
            if request.data:
                qs = CorpVersion.objects.filter(**request.data).values(*values_list)
            else:
                qs = CorpVersion.objects.all().values(*values_list)
            data = qs
            return Response({"state": "ok", 'data': data}, status=200)
        except:
            return Response({"state": "error"}, status=400)


class GetAllTask(APIView):
    def get(self, request, *args, **kwargs):
        try:
            if request.data.get('filters'):
                qs = Task.objects.filter(**request.data.get('filters'))
                qs = qs.values(*request.data.get('fields')) if qs else {}
            else:
                qs = Task.objects.all().values(*request.data.get('fields'))
            data = qs
            return Response({"state": "ok", 'data': data}, status=200)
        except:
            traceback.print_exc()
            return Response({"state": "error"}, status=400)


class GetTaskForTestSystem(APIView):
    def get(self, request, *args, **kwargs):
        try:
            qs = Task.objects.all()
            if request.data and request.data.get('TaskKind') and request.data.get('AppVersionText'):
                qs = qs.filter(TaskKind__contains=request.data.get('TaskKind'), AppVersionText__in=request.data.get('AppVersionText'))
            if request.data and request.data.get('fields'):
                data = qs.values(*request.data.get('fields'))
            else:
                data = qs.values()
            data = data[:50]
            return Response({"state": "ok", 'data': data}, status=200)
        except:
            traceback.print_exc()
            return Response({"state": "error"}, status=400)


class Task(APIView):
    """Task """

    def get(self, request, *args, **kwargs):
        if 'task_id' in kwargs.keys():
            task_id = kwargs['task_id']
            try:
                task = TaskModel.objects.get(Id=task_id)
                ser_data = TaskSerializer(task).data
                return Response({"msg": "Task found", "data": ser_data},
                                status=status.HTTP_200_OK)

            except TaskModel.DoesNotExist as e:
                return Response(
                    {"msg": f"Not Found", "detail":f"{e}"},
                    status=status.HTTP_404_NOT_FOUND)
