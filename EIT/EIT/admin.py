from django.contrib import admin
from import_export.admin import ImportExportModelAdmin
from .models import (
    SubSystem,
    Feature,
    ConstValue,
    Corp,
    Version,
    VersionRequest,
    VersionRequestSubsystem,
    VersionRequestTask,
    CorpVersion,
    CorpInvoiceTask,
    Team,
    Project,
    Kind,
    Status,
    Conversation,
    Request,
    RequestItem,
    Task,
    TaskCorps,
    TaskWorkhours,
    VOIP,
    Corptel,
    Userstel,
    VoipInvalidTellCount,
    VoipUnkownCaller
)
from django.db.models.functions import Length
from django.db.models import Q
import datetime
from . import filters


class ReadOnlyAdminMixin(admin.ModelAdmin):
    def has_add_permission(self, request):
        return False
    
    def has_delete_permission(self, request, obj = ...):
        return False
        
    def has_change_permission(self, request, obj = ...):
        if request.method in ['POST', 'PUT', 'PATCH']:
            return False
        return True
    
    

class BaseAdmin(admin.ModelAdmin):
    # used for remove whitespace nowrap (long changelist view columns)
    class Media:
        css = {
            'all': ('EIT/css/custom_admin.css',),
        }
        js = ('EIT/js/jquery-3.6.0.min.js','EIT/js/removeNoWrap.js',)


class RequestItemInline(admin.TabularInline):
    model = RequestItem
    extra = 0
    autocomplete_fields = ["Request", "Task"]


@admin.register(SubSystem)
class SubSystemAdmin(ImportExportModelAdmin, BaseAdmin):
    list_display = ("Code", "TeamCode", "Project")
    search_fields = ("Code",)
    list_filter = ("TeamCode", "Project")


@admin.register(Feature)
class FeatureAdmin(ImportExportModelAdmin, BaseAdmin):
    list_display = ("Code", "Name", "SubSysName", "LevelNumber", "TeamCode")
    list_filter = ("TeamCode",)
    search_fields = ("Code", "Name", "FullTitle")
    autocomplete_fields = ("OwnerFeature", "SubProductFeature", "BaseFeature")


@admin.register(ConstValue)
class ConstValueAdmin(ImportExportModelAdmin, BaseAdmin):
    list_display = ("Caption", "Code", "IsActive")
    search_fields = ("Caption", "Code")


@admin.register(Corp)
class CorpAdmin(ImportExportModelAdmin, BaseAdmin):
    list_display = ("CorpCode", "CorpName", "ActiveInService")
    search_fields = ("CorpCode", "CorpName")
    list_filter = ("ActiveInService",)


@admin.register(Version)
class VersionAdmin(ImportExportModelAdmin, BaseAdmin):
    list_display = ("VersionNumber", "CreateDate", "CloseDate")
    search_fields = ("VersionNumber", "CreateDate")
    ordering = ("-CreateDate",)


@admin.register(VersionRequest)
class VersionRequestAdmin(ImportExportModelAdmin, BaseAdmin):
    list_display = (
        "id",
        "Title",
        "VersionTaskKind",
        "VersionNumber",
        "CorpCode",
        "CreateDate",
        "SendDate",
    )
    search_fields = ("Title", "id", "CreateDate", "SendDate")
    list_filter = ("VersionTaskKind", "VersionNumber", "CorpCode")


@admin.register(VersionRequestSubsystem)
class VersionRequestSubsystemAdmin(ImportExportModelAdmin, BaseAdmin):
    list_display = ("id", "VersionRequest","VersionRequestCorpCode","VersionRequestCreateDate", "VersionRequestSendDate", "SubSystemCode", "TeamCode")
    search_fields = ("VersionRequest__Title","VersionRequest__CreateDate", "VersionRequest__SendDate")
    list_filter = (
        "SubSystemCode",
        "TeamCode",
        "VersionRequest__CorpCode"
    )
    autocomplete_fields = (
        "VersionRequest",
        "SubSystemCode",
    )

    @admin.display(description="شرکت")
    def VersionRequestCorpCode(self, obj):
        if obj.VersionRequest:
            return obj.VersionRequest.CorpCode
        return "-"
    
    @admin.display(description="تاریخ ایجاد")
    def VersionRequestCreateDate(self, obj):
        if obj.VersionRequest:
            return obj.VersionRequest.CreateDate
        return "-"
    
    
    @admin.display(description="تاریخ ارسال")
    def VersionRequestSendDate(self, obj):
        if obj.VersionRequest:
            return obj.VersionRequest.SendDate
        return "-"


@admin.register(VersionRequestTask)
class VersionRequestTaskAdmin(ImportExportModelAdmin, BaseAdmin):
    list_display = (
        "VersionRequestSubsystem",
        "Task",
        "TaskStartDate",
        "TaskEndDate",
        "VersionTaskKind",
        "TaskTeam",
        "TaskCorp",
    )
    search_fields = (
        "Task__Id",
        "Task__Title",
        "VersionRequestSubsystem__VersionRequest__Title",
        "Task__CreateDate",
        "Task__ActualEndDate",
    )
    list_filter = ("VersionTaskKind", "Task__TeamCode", "Task__CorpCode")
    autocomplete_fields = ("Task", "VersionRequestSubsystem")

    @admin.display(description="تیم تسک")
    def TaskTeam(self, obj):
        if obj.Task:
            return obj.Task.TeamCode

    @admin.display(description="شرکت تسک")
    def TaskCorp(self, obj):
        if obj.Task:
            return obj.Task.CorpCode

    @admin.display(description="تاریخ ایجاد تسک")
    def TaskStartDate(self, obj):
        if obj.Task:
            return obj.Task.CreateDate

    @admin.display(description="تاریخ پایان تسک")
    def TaskEndDate(self, obj):
        if obj.Task:
            return obj.Task.ActualEndDate


@admin.register(CorpVersion)
class CorpVersionAdmin(ImportExportModelAdmin, BaseAdmin):
    list_display = ("CorpCode", "YearNumber", "VersionNumber", "SendDate")
    search_fields = ("SendDate",)
    list_filter = (
        "CorpCode",
        "YearNumber",
        "VersionNumber",
    )


@admin.register(CorpInvoiceTask)
class CorpInvoiceTaskAdmin(ImportExportModelAdmin, BaseAdmin):
    list_display = ("CorpVersion", "Task", "FinalWorkHoursMinutes")
    search_fields = ("Task__Id",)


@admin.register(Team)
class TeamAdmin(ImportExportModelAdmin, BaseAdmin):
    list_display = ("TeamCode", "TeamName")
    search_fields = ("TeamCode", "TeamName")


@admin.register(Project)
class ProjectAdmin(ImportExportModelAdmin, BaseAdmin):
    list_display = ("Project", "TeamCode")
    search_fields = ("Project",)
    list_filter = ("TeamCode",)


@admin.register(Kind)
class KindAdmin(ImportExportModelAdmin, BaseAdmin):
    list_display = ("Title", "KindType", "KindCode")
    search_fields = ("Title",)
    list_filter = ("KindType",)


@admin.register(Status)
class StatusAdmin(ImportExportModelAdmin, BaseAdmin):
    list_display = ("Title", "StatusType", "IsFinishStatus")
    search_fields = ("Title",)
    list_filter = ("StatusType",)


@admin.register(Conversation)
class ConversationAdmin(ImportExportModelAdmin, BaseAdmin):
    list_display = (
        "MessageCode",
        "Title",
        "ConversationStatus",
        "Project",
        "TeamCode",
        "CorpCode",
        "CreateDate",
        "LastMidifyDate",
        "ResponseDate",
    )
    search_fields = (
        "MessageCode",
        "Title",
        "CreateDate",
        "LastMidifyDate",
        "ResponseDate",
    )
    list_filter = ("TeamCode", "CorpCode", "ConversationStatus", "Task__TaskStatus")
    autocomplete_fields = ("MessageSource", "Task")

    @admin.display(description="وضعیت تسک")
    def TaskStatus(self, obj):
        if self.Task:
            return self.Task.TaskStatus
        return "-"


@admin.register(Request)
class RequestAdmin(ImportExportModelAdmin, BaseAdmin):
    list_display = (
        "Id",
        "Title",
        "RequestStatus",
        "RequestKind",
        "CorpCode",
        "ToCorpCode",
        "Project",
        "TeamCode",
        "CreateDate",
    )
    search_fields = ("Title", "Id", "CreateDate")
    list_filter = ("RequestStatus", "RequestKind", "CorpCode", "TeamCode", "IsFinished")
    autocomplete_fields = ("RelatedRequest",)
    inlines = [RequestItemInline]


@admin.register(Corptel)
class CorptelAdmin(ImportExportModelAdmin, BaseAdmin):
    list_display = (
        "CorpCode",
        "TelNumber"
    )
    search_fields = ("TelNumber",)
    list_filter = ("CorpCode",)

    

@admin.register(VoipInvalidTellCount)
class VoipInvalidTellCountAdmin(ImportExportModelAdmin, BaseAdmin, ReadOnlyAdminMixin):
    list_display = (
        "UserName",
        "Tel",
        "StartDate",
        "EndDate",
        "StartDateMiladi",
        "EndDateMiladi"
    )
    search_fields = ("UserName", "Tel")

@admin.register(VoipUnkownCaller)
class VoipUnkownCallerAdmin(ImportExportModelAdmin, BaseAdmin, ReadOnlyAdminMixin):
    list_display = (
        "CallNumber",
        "CallCount"
    )
    search_fields = ("CallNumber",)


@admin.register(Userstel)
class UserstelAdmin(ImportExportModelAdmin, BaseAdmin):
    list_display = (
        "UserName",
        "Tel",
        "StartDate",
        "EndDate",
        "StartDateMiladi",
        "EndDateMiladi"
    )
    search_fields = ("UserName", "Tel")


@admin.register(RequestItem)
class RequestItemAdmin(ImportExportModelAdmin, BaseAdmin):
    list_display = (
        "Id",
        "Title",
        "RequestTeam",
        "RequestTitle",
        "RequestKind",
        "RequestStatus",
        "RequestItemStatus",
        "CreateDate",
    )
    search_fields = ("Title", "Id", "CreateDate")
    list_filter = (
        "RequestItemStatus",
        "Request__RequestStatus",
        "RequestItemKind",
        "Request__RequestKind",
        "Request__TeamCode",
    )

    autocomplete_fields = [
        "Request",
        "Task",
    ]

    @admin.display(description="وضعیت درخواست")
    def RequestStatus(self, obj):
        if obj.Request:
            return obj.Request.RequestStatus
        return "-"

    @admin.display(description="عنوان درخواست کوتاه شده")
    def RequestTitle(self, obj):
        if obj.Request:
            return obj.Request.Title[:50]
        return "-"

    @admin.display(description="تیم تسک")
    def RequestTeam(self, obj):
        if obj.Request:
            return obj.Request.TeamCode
        return "-"

    @admin.display(description="نوع درخواست")
    def RequestKind(self, obj):
        if obj.Request:
            return obj.Request.RequestKind
        return "-"


@admin.register(Task)
class TaskAdmin(ImportExportModelAdmin, BaseAdmin):
    list_display = (
        "Id",
        "Title",
        "TaskKind",
        "IssueKind",
        "TaskStatus",
        "IssueStatus",
        "TeamCode",
        "CorpCode",
        "CreateDate",
        "ActualEndDate",
    )
    search_fields = ("Id", "Title", "CreateDate", "ActualEndDate")
    list_filter = (
        "TaskKind",
        "IssueKind",
        "TaskStatus",
        "IssueStatus",
        "TeamCode",
        "CorpCode",
    )
    autocomplete_fields = ("ParentTask", "RootTask", "RequestItem", "Request")


@admin.register(TaskCorps)
class TaskCorpsAdmin(ImportExportModelAdmin, BaseAdmin):
    list_display = (
        "TaskCode",
        "Task",
        "TaskKind",
        "CorpCode",
        "WorkHourMinutesReal",
        "WorkHourMinutesPM",
        "WorkHourMinutesInvoice",
        "TaskStartDate",
        "TaskEndDate",
    )
    search_fields = (
        "Task__Id",
        "Task__CreateDate",
        "Task__ActualEndDate",
        "Task__Title",
    )
    list_filter = (
        filters.TaskCorpWorkHourMinutesRealFilter,
        filters.TaskCorpWorkHourMinutesPMFilter,
        filters.TaskCorpWorkHourMinutesInvoiceFilter,
        "Task__TaskKind",
        "CorpCode",
        "Task__TeamCode",
    )
    autocomplete_fields = ["Task", "RequestItem"]

    @admin.display(description="نوع تسک")
    def TaskKind(self, obj):
        if obj.Task:
            return obj.Task.TaskKind
        return "-"

    @admin.display(description="تسک")
    def TaskCode(self, obj):
        if obj.Task:
            return obj.Task.Id
        return "-"

    @admin.display(description="تاریخ ایجاد تسک")
    def TaskStartDate(self, obj):
        if obj.Task:
            return obj.Task.CreateDate

    @admin.display(description="تاریخ پایان تسک")
    def TaskEndDate(self, obj):
        if obj.Task:
            return obj.Task.ActualEndDate


class ValidTaskWorkHoursFilter(admin.SimpleListFilter):
    title = "دارای ساعت کاری معتبر"
    parameter_name = "valid_wh"

    def lookups(self, request, model_admin):
        return (
            ("1", "آری"),
            ("0", "خیر"),
        )

    def queryset(self, request, queryset):
        # No need to consider null because Model doesnt allows NULL value
        if self.value() == "1":
            return queryset.exclude(WorkHoursMinutes=0)
        if self.value() == "0":
            return queryset.filter(WorkHoursMinutes=0)
        return queryset


@admin.register(TaskWorkhours)
class TaskWorkhoursAdmin(ImportExportModelAdmin, BaseAdmin):
    list_display = (
        "TaskID",
        "TaskCorp",
        "TaskTeam",
        "TaskStatus",
        "WorkTimeDate",
        "WorkHoursMinutes",
    )
    search_fields = ("Task__Id", "Task__Title", "WorkTimeDate")
    list_filter = (
        ValidTaskWorkHoursFilter,
        "Task__TaskStatus",
        "Task__TeamCode",
        "Task__CorpCode",
    )
    autocomplete_fields = ("Task",)

    @admin.display(description="شناسه تسک")
    def TaskID(self, obj):
        if obj.Task:
            return obj.Task.Id
        return "-"

    @admin.display(description="شرکت تسک")
    def TaskCorp(self, obj):
        if obj.Task and obj.Task.CorpCode:
            return obj.Task.CorpCode
        return "-"

    @admin.display(description="تیم تسک")
    def TaskTeam(self, obj):
        if obj.Task and obj.Task.TeamCode:
            return obj.Task.TeamCode
        return "-"

    @admin.display(description="وضعیت تسک")
    def TaskStatus(self, obj):
        if obj.Task:
            return obj.Task.TaskStatus
        return "-"



class VoipCustomFilter(admin.SimpleListFilter):
    title = "کوئری ها"
    parameter_name = "qtype"

    def lookups(self, request, model_admin):
        return (
            ("0", "شماره های ناشناس شرکت بیمه"),
            ("1", "شماره های ناشناس داخلی"),
        )

    def queryset(self, request, queryset):
        if self.value() == "0":
            return (
                queryset.annotate(
                    source_tel_len=Length("CallSource"),
                    dest_tel_len=Length("CallDestination"),
                )
                .filter(
                    (Q(source_tel_len__gt=3) & Q(CorpCode__isnull=True))
                    | (Q(dest_tel_len__gt=3) & Q(CorpCode__isnull=True))
                )
                .filter(CallDate__gte=datetime.date(2024, 3, 21))
            )
        if self.value() == "1":
            return (
                queryset.annotate(
                    source_tel_len=Length("CallSource"),
                    dest_tel_len=Length("CallDestination"),
                )
                .filter(
                    (Q(source_tel_len=3) & Q(FromTeamCode__isnull=True))
                    | (Q(dest_tel_len=3) & Q(ToTeamCode__isnull=True))
                )
                .filter(CallDate__gte=datetime.date(2024, 3, 21))
            )
        return queryset


class VoipInOutInternalFilter(admin.SimpleListFilter):
    title = "نوع تماس"
    parameter_name = "call_type"

    def lookups(self, request, model_admin):
        return (
            ("0", "داخلی"),
            ("1", "غیرداخلی (ورودی / خروجی / نامشخص)"),
        )

    def queryset(self, request, queryset):
        if self.value() == "0":
            return queryset.annotate(
                source_tel_len=Length("CallSource"),
                dest_tel_len=Length("CallDestination"),
            ).filter(Q(source_tel_len=3) & Q(dest_tel_len=3))
        if self.value() == "1":
            return queryset.annotate(
                source_tel_len=Length("CallSource"),
                dest_tel_len=Length("CallDestination"),
            ).exclude(Q(source_tel_len=3) & Q(dest_tel_len=3))
        return queryset


@admin.register(VOIP)
class VOIPAdmin(ImportExportModelAdmin, BaseAdmin):
    list_display = (
        "CallDate",
        "CallSource",
        "CallDestination",
        "CorpCode",
        "FromTeamCode",
        "ToTeamCode",
        "callKind",
    )
    search_fields = ("CallSource", "CallDestination", "CallDate")
    list_filter = (
        VoipCustomFilter,
        VoipInOutInternalFilter,
        "ToTeamCode",
        "FromTeamCode",
        "CorpName",
    )
    ordering = ("-CallDate",)

    @admin.display(description="نوع تماس")
    def callKind(self, obj):
        kind = "نامشخص"
        if not (obj.CallSource and obj.CallDestination):
            return kind
        if len(obj.CallSource) == 3 and len(obj.CallDestination) != 3:
            return "خروجی"

        if len(obj.CallSource) != 3 and len(obj.CallDestination) == 3:
            return "ورودی"

        if len(obj.CallSource) == 3 and len(obj.CallDestination) == 3:
            return "داخلی"

        return kind
