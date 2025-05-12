from django.urls import path
import EIT.views as EITViews
from EIT.api import (
    GetCorp,
    GetTaskByIds,
    GetTaskByIdsRetId,
    GetAllEitViewVersion,
    FindCorp,
    GetFeatures,
    GetFeatureTitle,
    GetAllFeatures,
    GetViewFeatureTeam,
    GetAllCorpVersions,
    GetAllTask,
    GetTaskForTestSystem,
    Task
)


app_name = 'EIT'
urlpatterns = [
    path('api/get-corp/', GetCorp.as_view(),  name="get_corp"),
    path('api/get-task-by-ids/', GetTaskByIds.as_view(),  name="get_task_by_ids"),
    path('api/get-task-by-ids-ret-id/', GetTaskByIdsRetId.as_view(),  name="get_task_by_ids_ret_id"),
    path('api/get-all-eit-view-version/', GetAllEitViewVersion.as_view(),  name="get_all_eit_view_version"),
    path('api/find-corp/', FindCorp.as_view(),  name="find_corp"),
    path('api/get-all-features/', GetAllFeatures.as_view(),  name="get_all_features"),
    path('api/get-features/', GetFeatures.as_view(),  name="get_features"),
    path('api/get-feature-title/', GetFeatureTitle.as_view(),  name="get_feature_title"),
    path('api/get-view-feature-team/', GetViewFeatureTeam.as_view(),  name="get_view_feature_team"),
    path('api/get-all-corp-versions/', GetAllCorpVersions.as_view(),  name="get_all_corp_versions"),
    path('api/get-all-task/', GetAllTask.as_view(),  name="get_all_task"),
    path('api/get-task-for-test-system/', GetTaskForTestSystem.as_view(),  name="get_task_for_test_system"),
    path('api/task/<int:task_id>', Task.as_view(),  name="task"),

]