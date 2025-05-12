from rest_framework import serializers
from EIT.models import Corp,EIT_View_Verion,Task

class CorpSerializer(serializers.ModelSerializer):

    class Meta:
        model = Corp
        fields = '__all__'


class EITViewVerionSerializer(serializers.ModelSerializer):
    class Meta:
        model = EIT_View_Verion
        fields = '__all__'


class TaskSerializer(serializers.ModelSerializer):
    class Meta:
        model = Task
        fields = ['Id','Title']