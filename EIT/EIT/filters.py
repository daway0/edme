from django.contrib import admin

class TaskCorpWorkHourMinutesRealFilter(admin.SimpleListFilter):
    title = 'ساعت کارکرد واقعی'
    parameter_name = 'valid_whr'  

    def lookups(self, request, model_admin):
        
        return (
            ('1', 'آری'),
            ('0', 'خیر'),
        )

    def queryset(self, request, queryset):
        # No need to consider null because Model doesnt allows NULL value
        if self.value() == '1':
            return queryset.exclude(WorkHourMinutesReal=0)
        if self.value() == '0':
            return queryset.filter(WorkHourMinutesReal=0)
        return queryset
    
class TaskCorpWorkHourMinutesPMFilter(admin.SimpleListFilter):
    title = 'ساعت کارکرد ثبت شده در PM'
    parameter_name = 'valid_whpm'  

    def lookups(self, request, model_admin):
        
        return (
            ('1', 'آری'),
            ('0', 'خیر'),
        )

    def queryset(self, request, queryset):
        # No need to consider null because Model doesnt allows NULL value
        if self.value() == '1':
            return queryset.exclude(WorkHourMinutesPM=0)
        if self.value() == '0':
            return queryset.filter(WorkHourMinutesPM=0)
        return queryset
    
class TaskCorpWorkHourMinutesInvoiceFilter(admin.SimpleListFilter):
    title = 'ساعت کارکرد مندرج در صورت حساب'
    parameter_name = 'valid_whinv'  

    def lookups(self, request, model_admin):
        
        return (
            ('1', 'آری'),
            ('0', 'خیر'),
        )

    def queryset(self, request, queryset):
        # No need to consider null because Model doesnt allows NULL value
        if self.value() == '1':
            return queryset.exclude(WorkHourMinutesInvoice=0)
        if self.value() == '0':
            return queryset.filter(WorkHourMinutesInvoice=0)
        return queryset