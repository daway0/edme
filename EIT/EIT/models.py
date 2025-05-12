from django.db import models
from django_middleware_global_request.middleware import get_request

class AbstractDateTime(models.Model):
    class Meta:
        abstract=True
    CreateDate=models.DateTimeField(
        auto_now_add=True, null=True,blank=True, verbose_name="تاریخ ایجاد")
    ModifyDate=models.DateTimeField(
        auto_now=True, null=True,blank=True, verbose_name="تاریخ ویرایش")
    # CreatorUserName=models.ForeignKey(
    #     HRMODEL.Users, db_constraint=False, null=True,blank=True, verbose_name="ایجاد کننده",
    #     related_name="%(app_label)s_%(class)s_cr"
    # ,on_delete=models.DO_NOTHING)
    CreatorUserName=models.CharField(max_length=100, null=True, blank=True, default=None, verbose_name="ایجاد کننده")
    # ModifierUserName=models.ForeignKey(
    #     HRMODEL.Users, db_constraint=False, null=True,blank=True, verbose_name="ویرایش کننده", on_delete=models.DO_NOTHING
    #     ,related_name="%(app_label)s_%(class)s_md")
    CreatorUserName=models.CharField(max_length=100, null=True,blank=True, default=None, verbose_name="ویرایش کننده")

    def save(self,*args,**kwargs):
        request=get_request()
        if request.user and request.user.is_authenticated:
            username=request.user.UserName
        else:
            username=None

        if self._state.adding:
            # insert new data
            self.CreatorUserName=username
        else:
            # update data
            self.ModifierUserName=username

        super().save(*args,**kwargs)


class SubSystem(models.Model):
    TeamCode=models.ForeignKey("Team", on_delete=models.SET_NULL, null=True, verbose_name='تیم', db_column='TeamCode')
    Code=models.CharField(max_length=100, verbose_name='نام سیستم', primary_key=True)
    Project=models.ForeignKey(to="Project", verbose_name="پروژه مربوطه", null=True, on_delete=models.SET_NULL)

    class Meta:
        verbose_name='زیرسیستم'
        verbose_name_plural='زیرسیستم ها'
    
    def __str__(self):
        return self.Code


class Feature(models.Model):
    Code=models.IntegerField(verbose_name='کد', primary_key=True, db_column='Code')
    Name=models.CharField(max_length=100, verbose_name='نام ')
    Title=models.CharField(verbose_name='عنوان', max_length=1000)
    OwnerFeature=models.ForeignKey('Feature', related_name='OwnerFeatures',verbose_name='مالکیت', null=True
                                   , blank=True, on_delete=models.CASCADE)
    SubProductFeature=models.ForeignKey('Feature', related_name='SubProductFeatures', verbose_name='ویژگی فرعی', null=True
                                          , blank=True, on_delete=models.CASCADE)
    BaseFeature=models.ForeignKey('Feature', related_name='BaseFeatures', verbose_name='ویژگی پایه', null=True
                                        , on_delete=models.CASCADE, blank=True)
    FullTitle=models.CharField(verbose_name='نام کامل', null=True, blank=True, max_length=4000)

    SubSysName=models.CharField(verbose_name='نام سیستم', null=True, blank=True, max_length=100)
    LevelNumber=models.IntegerField(default=0)
    ParentHierarchy=models.CharField(max_length=500, null=True, blank=True, default="")
    TeamCode=models.CharField(max_length=3, null=True, blank=True, default="", verbose_name="تیم")

    class Meta:
        verbose_name='قابلیت'
        verbose_name_plural='قابلیت ها'


    @property
    def Isleaf(self):
        IL=Feature.object.filter(OwnerFeature=self.Code)
        if IL is None:
            return True
        return False

    def __str__(self):
        if self.FullTitle is None:
            return ''
        return str(self.FullTitle[:100]) + str(self.Code)


class ConstValue(models.Model):
    """جدول مقادیر ثابت حاوی مقادیر کمکی است برای جداول دیگر برای مثال اطلاعات انواع آدرس ویا انواع قرارداد در این جدول قرار می گیرد و صرفا آیدی آنها به عنولن کلید خارجی استفاده می شود."""
    class Meta:
        verbose_name = "مقدار ثابت"
        verbose_name_plural = "مقادیر ثابت"
        ordering = ["Parent_id", "OrderNumber"]

    Caption = models.CharField(max_length=50, verbose_name="عنوان")
    Code = models.CharField(max_length=100, verbose_name="کد")
    Parent = models.ForeignKey("ConstValue", verbose_name="شناسه پدر", on_delete=models.CASCADE, null=True, blank=True)
    IsActive = models.BooleanField(verbose_name="فعال است؟", default=True)
    OrderNumber = models.PositiveSmallIntegerField(verbose_name="شماره ترتیب", null=True, blank=True, default=1)
    ConstValue = models.IntegerField(verbose_name="مقدار مربوطه", null=True, blank=True)

    def __str__(self):
        return self.Caption

    @property
    def ParentTitle(self):
        return self.Parent.Caption

class Corp (models.Model):
    class Meta:
        verbose_name='شرکت'
        verbose_name_plural='شرکت ها'

    CorpCode=models.CharField(primary_key=True, max_length=3, verbose_name='کد شرکت')
    CorpName=models.CharField(max_length=50, verbose_name='نام شرکت')
    ActiveInService=models.BooleanField(default=True, verbose_name=' کتاب')
    EnglishName=models.CharField(max_length=30, verbose_name='نام لاتین شرکت بیمه', null=True)
    FullTitle = models.CharField(max_length=100, verbose_name='عنوان کامل شرکت بیمه', null=True)

    def __str__(self):
        return self.CorpName


    @property
    def get_code(self):
        return self.CorpCode

    def get_pk(self):
        return self.pk

    def get_cls_name(self):
        return self.__class__.__name__


class EIT_View_Feature_Leaf(models.Model):
    class Meta:
        verbose_name='ویژگی'
        verbose_name_plural='ویژگی ها'
        db_table='EIT_View_Feature_Leaf'
        managed=False
    Code=models.IntegerField(verbose_name='کد', primary_key=True, db_column='Code')
    FullTitle=models.CharField(verbose_name='نام کامل', null=True, blank=True, max_length=4000)

    def __str__(self):
        return str(self.FullTitle) + '(' + str(self.Code) + ')'

class EIT_View_Feature_Team(models.Model):
    class Meta:
        verbose_name='ویژگی تیم'
        verbose_name_plural='ویژگی های تیم ها'
        db_table='EIT_View_Feature_Team'
        managed=False
    Code=models.IntegerField(verbose_name='کد', primary_key=True, db_column='Code')
    FullTitle=models.CharField(verbose_name='نام کامل', null=True, blank=True, max_length=4000)
    TeamCode=models.CharField(max_length=3, null=True,blank=True,verbose_name='کد تیم')
    OwnerFeature_id=models.IntegerField(verbose_name='کد', null=True)

    def __str__(self):
        return str(self.FullTitle) + '(' + str(self.Code) + ')'


class Version(models.Model):
    VersionNumber=models.CharField(max_length=10,verbose_name='نسخه', primary_key=True)
    CreateDate=models.CharField(max_length=10, verbose_name='تاریخ ایجاد نسخه', null=True)
    CloseDate=models.CharField(max_length=10, verbose_name='تاریخ بستن نسخه', null=True)

    class Meta:
        verbose_name='نسخه'
        verbose_name_plural='نسخه ها'
        ordering = ["-VersionNumber"]
    
    def __str__(self):
        return self.VersionNumber

class VersionRequest(models.Model):
    id = models.PositiveIntegerField(primary_key=True, verbose_name='شناسه درخواست نسخه',
                                     help_text='این شناسه برابر با مقدار PM است و شمارنده خودکار نیست')
    Title = models.CharField(max_length=500, verbose_name='عنوان نسخه ارسالی')
    VersionTaskKind = models.ForeignKey(to='Kind',limit_choices_to={"KindType":"VR"}, on_delete=models.CASCADE, verbose_name='نوع نسخه')
    CorpCode = models.ForeignKey(to=Corp, on_delete=models.CASCADE, db_column='CorpCode',
                                 verbose_name='شرکت مربوطه')
    VersionNumber = models.ForeignKey(to=Version, on_delete=models.CASCADE, db_column='VersionNumber',
                                      verbose_name='شماره نسخه')
    CreateDate = models.CharField(max_length=10, verbose_name='تاریخ ایجاد نسخه',
                                  help_text='تاریخ به شمسی در قالب YYYY/MM/DD')
    SendDate = models.CharField(max_length=10, verbose_name='تاریخ ارسال', null=True,
                                help_text='تاریخ به شمسی در قالب YYYY/MM/DD')
    SendTime = models.TimeField(verbose_name='زمان ارسال نسخه', null=True)

    class Meta:
        verbose_name='درخواست نسخه'
        verbose_name_plural='درخواست نسخه ها'

    def __str__(self):
        return self.Title

class VersionRequestSubsystem(models.Model):
    id = models.PositiveIntegerField(primary_key=True, verbose_name='شناسه درخواست نسخه',
                                     help_text='این شناسه برابر با مقدار PM است و شمارنده خودکار نیست')

    VersionRequest = models.ForeignKey(to='VersionRequest', on_delete=models.CASCADE, verbose_name='شناسه درخواست نسخه')
    SubSystemCode = models.ForeignKey(to='SubSystem', on_delete=models.CASCADE,db_column='SubSystemCode',
                                       verbose_name='کد زیرسیستم')
    TeamCode = models.ForeignKey(to='Team', on_delete=models.CASCADE,db_column='TeamCode',
                                       verbose_name='کد تیم')
    ClientDescription = models.TextField(verbose_name='توضیحات مشتری', null=True)
    FirstSigner = models.CharField(max_length=50, verbose_name='تایید کننده اول', null=True)
    SecondSigner = models.CharField(max_length=50, verbose_name='تایید کننده دوم', null=True)
    ApprovalTestSender = models.CharField(max_length=50, verbose_name='تایید کننده تست', null=True)
    RequestOwner = models.CharField(max_length=50, verbose_name='مالک درخواست', null=True)
    VersionStatus = models.ForeignKey(to='Status',limit_choices_to={"StatusType":"VR"}, on_delete=models.CASCADE, verbose_name='وضعیت درخواست نسخه')

    class Meta:
        verbose_name='زیر سیستم درخواست نسخه'
        verbose_name_plural='زیر سیستم های درخواست نسخه ها'

    def __str__(self):
        return self.VersionRequest.Title

class VersionRequestTask(models.Model):
    VersionRequestSubsystem = models.ForeignKey(to='VersionRequestSubsystem', on_delete=models.CASCADE,
                                                verbose_name='شناسه درخواست زیرسیستم نسخه مربوطه')
    VersionTaskKind = models.ForeignKey(to='ConstValue', limit_choices_to={"Code__istartswith":"VersionTaskKind_"}, verbose_name='نوع تسک مرتبط', 
                                        on_delete=models.SET_NULL, null=True)
    Task = models.ForeignKey(to='Task', on_delete=models.CASCADE, verbose_name='شناسه تسک')
    class Meta:
        verbose_name='تسک درخواست نسخه'
        verbose_name_plural='تسک های درخواست نسخه ها'
        
    def __str__(self):
        return str(self.id)
    
class CorpVersion(models.Model):
    class Meta:
        verbose_name='نسخه شرکت'
        verbose_name_plural='نسخه های شرکت ها'

    CorpCode=models.ForeignKey('Corp',verbose_name='نام شرکت',on_delete=models.CASCADE, db_column='CorpCode')
    YearNumber=models.IntegerField(verbose_name='سال', null=True)
    VersionNumber=models.ForeignKey(to='Version', verbose_name='نسخه', null=False, on_delete=models.CASCADE, db_column='VersionNumber')
    SendDate=models.CharField(max_length=10,verbose_name='تاریخ ارسال نسخه',null=True)
    ApproveDate= models.CharField(max_length=10,null=True,blank=True,verbose_name='تاریخ تایید صورت حساب')
    InvoiceId = models.PositiveIntegerField(verbose_name='شناسه صورت حساب', null=True)

    def __str__(self):
        return str(self.VersionNumber) + '(' + self.CorpCode.CorpCode + ')'

class CorpInvoiceTask(models.Model):
    CorpVersion=models.ForeignKey(to='CorpVersion', on_delete=models.CASCADE, verbose_name='شناسه نسخه ')
    Task=models.ForeignKey(to='Task', on_delete=models.CASCADE, verbose_name='شناسه تسک ', null=True)
    FinalWorkHoursMinutes=models.PositiveIntegerField(verbose_name='ساعت کارکرد نهایی بر حسب دقیقه')
    IsPrimaryRequester = models.BooleanField(verbose_name='شرکت درخواست کننده اصلی بوده؟', default=0, null=True) 
    TeamCode=models.ForeignKey(to='Team',db_column='TeamCode', on_delete=models.CASCADE, verbose_name='کد تیم ', null=True)

    class Meta:
        verbose_name='تسک صورت حساب'
        verbose_name_plural='تسک صورت حساب ها'

    def __str__(self):
        return f'{self.CorpVersion} - TaskId : {self.Task}'

class Team(models.Model):
    TeamCode=models.CharField(max_length=3, verbose_name='کد تیم', primary_key=True)
    TeamName=models.CharField(max_length=50, verbose_name='نام تیم')
    
    class Meta:
        verbose_name='تیم'
        verbose_name_plural='تیم ها'    
    
    def __str__(self):
        return self.TeamName
    
class Project(models.Model):
    Project=models.CharField(verbose_name='عنوان پروژه', max_length=50)
    TeamCode=models.ForeignKey(to="Team", verbose_name='تیم مربوطه', on_delete=models.CASCADE, null=True, db_column='TeamCode')

    class Meta:
        verbose_name='پروژه'
        verbose_name_plural='پروژه ها'

    def __str__(self):
        return self.Project
    
class Kind(models.Model):
    Title=models.CharField(max_length=100, verbose_name='نوع', null=False)
    KindTypeChoices = [('TA', 'تسک'),('RE', 'درخواست'),('RI','مورد درخواست'),('IS','Issue جیرا'),('VR','درخواست نسخه')]
    KindType = models.CharField(max_length=2, choices=KindTypeChoices, verbose_name='دسته بندی نوع', default='TA',
                                help_text='نوع می تواند مربوط به تسک یا درخواست یا مورد درخواست باشد')
    KindCode = models.CharField(max_length=10, verbose_name='کد نوع',null=True)
    JiraKind = models.CharField(max_length=50, verbose_name='نوع معادل در جیرا',null=True)

    class Meta:
        verbose_name='نوع تسک'
        verbose_name_plural='انواع تسک ها'

    def __str__(self):
        return self.Title
    
class Status(models.Model):
    Title=models.CharField(max_length=100, verbose_name='وضعیت', null=False)
    StatusType_Choices = [('TA', 'تسک'),('RE', 'درخواست'),('RI','مورد درخواست'),('IS','Issue جیرا'),('CO','پیام ها'),('VR','درخواست نسخه')]
    StatusType = models.CharField(max_length=2, choices=StatusType_Choices, verbose_name='نوع وضعیت',
                                  help_text='وضعیت می تواند مربوط به تسک، پیام، درخواست یا مورد درخواست باشد')
    IsFinishStatus=models.BooleanField(verbose_name='وضعیت خاتمه یافته است؟', default=False)
    StatusCode = models.CharField(max_length=50, verbose_name='کد وضعیت', null=True)

    class Meta:
        verbose_name=' وضعیت'
        verbose_name_plural='وضعیت ها'

    def __str__(self):
        return self.Title

class Conversation(models.Model):
    MessageCode=models.CharField(max_length=15,primary_key=True,verbose_name='شناسه پیام')
    Title=models.CharField(max_length=500,null=True,verbose_name='عنوان پیام')
    ConversationStatus=models.ForeignKey(to='Status',limit_choices_to={"StatusType":"CO"},on_delete=models.SET_NULL,null=True,verbose_name='وضعیت پیام')
    
    CreateDate=models.CharField(max_length=10,null=True,verbose_name='تاریخ ایجاد پیام')
    CreateTime=models.CharField(max_length=10,null=True,verbose_name='ساعت ایجاد پیام')
    LastMidifyDate=models.CharField(max_length=10,null=True,verbose_name='تاریخ ایجاد آخرین پاسخ')
    LastModifyTime=models.CharField(max_length=10,null=True,verbose_name='ساعت ایجاد آخرین پاسخ')
    ResponseDate=models.CharField(max_length=10,null=True,verbose_name='تاریخ پاسخگویی پیام')
    ResponseTime=models.CharField(max_length=10,null=True,verbose_name='ساعت پاسخ گویی پیام')
    
    
    EitWaitTime=models.CharField(max_length=50,null=True,verbose_name='زمان انتظار فناوران')
    BimeWaitTime=models.CharField(max_length=50,null=True,verbose_name='زمان انتظار شرکت بیمه')
    Duration=models.PositiveIntegerField(verbose_name='مدت زمان به دقیقه', null=True)

    Project=models.ForeignKey(to='Project',null=True, on_delete=models.SET_NULL ,verbose_name='پروژه مرتبط')
    TeamCode=models.ForeignKey(to='Team', null=True,on_delete=models.SET_NULL ,verbose_name='تیم مرتبط', db_column='TeamCode')    
    CorpCode=models.ForeignKey(to='Corp', related_name='Corp',null=True , on_delete=models.SET_NULL ,verbose_name='شرکت مربوطه', db_column='CorpCode')
    FromEIT=models.BooleanField(default=False, verbose_name='پیام از جانب شرکت فناوران بوده است؟')    

    FromUser=models.CharField(max_length=50,null=True,verbose_name='کاربر مربوطه')
    LastFromUser=models.CharField(max_length=50,null=True,verbose_name='آخرین کاربر مربوطه')
    
    MessageSource=models.ForeignKey(to=ConstValue, limit_choices_to={"Code__istartswith":"MessageSource_"}, on_delete=models.SET_NULL,null=True,verbose_name='مبدا پیام',
                                    help_text='مبدا پیام می تواند سیستم محاوره شرکت بیمه، محاوره PM یا پیام کاربران باشد')
    Task=models.ForeignKey(to='Task',on_delete=models.SET_NULL,null=True,verbose_name='شناسه تسکر مرتبط')

    IsDeleted=models.BooleanField(default=False,verbose_name='آیا این رکورد حذف شده است')
    RecordDate=models.DateTimeField(auto_created=True,verbose_name='تاریخ ثبت رکورد')    

    class Meta:
        verbose_name='پیام'
        verbose_name_plural='پیام ها'

    def __str__(self):
        return f'{self.Title}'        

class Request(models.Model):
    Id=models.IntegerField(primary_key=True, verbose_name='شناسه درخواست')
    Title = models.CharField(max_length=500, verbose_name='عنوان درخواست')
    IsPublic = models.BooleanField(verbose_name='ایا درخواست عمومی است؟', default=False)
    RequestStatus = models.ForeignKey(to='Status', limit_choices_to={"StatusType":"RE"}, verbose_name='وضعیت درخواست', 
                                      on_delete=models.SET_NULL, null=True)
    RelatedRequest = models.ForeignKey(to='Request', verbose_name='درخواست مرتبط',
                                       on_delete=models.SET_NULL, null=True)
    RequestKind = models.ForeignKey(to='Kind', limit_choices_to={"KindType":"RE"}, verbose_name='نوع درخواست',
                                    on_delete=models.SET_NULL, null=True)
    
    CorpCode = models.ForeignKey(to='Corp', verbose_name='شرکت درخواست دهنده', related_name='FromCorpCode',
                                 null=True, on_delete=models.SET_NULL, db_column='CorpCode')
    ToCorpCode  = models.ForeignKey(to='Corp', verbose_name='شرکت درخواست دهنده', related_name='ToCorpCode',
                                 null=True, on_delete=models.SET_NULL, db_column='ToCorpCode') 
    Project = models.ForeignKey(to='Project', verbose_name='پروژه', 
                                null=True, on_delete=models.SET_NULL)
    TeamCode = models.ForeignKey(to='Team', verbose_name='تیم مربوطه',
                                 null=True, on_delete=models.SET_NULL, db_column='TeamCode')
    
    CreateDate = models.CharField(max_length=20, verbose_name='تاریخ و ساعت ایجاد',
                                  help_text='تاریخ به شمسی و ساعت به آن اضافه شده است')
    IsFinished=models.BooleanField(default=False,verbose_name='پایان یافته است؟')
    
    CreatorUser=models.CharField(max_length=100, null=True, blank=True, default=None, verbose_name='نام کاربری تعریف کننده درخواست')
    CreatorUserNationalCode=models.CharField(max_length=10,null=True, verbose_name='کد ملی تعریف کننده درخواست')
    OwnerUser=models.CharField(max_length=100, null=True, blank=True, default=None, verbose_name='نام کاربری مالک درخواست')
    OwnerUserNationalCode=models.CharField(max_length=10, null=True,verbose_name='کد ملی مالک درخواست')

    class Meta:
        verbose_name='درخواست'
        verbose_name_plural='درخواست ها'

    def __str__(self):
        return self.Title
class RequestItem(models.Model):
    Id=models.IntegerField(primary_key=True, verbose_name='شناسه مورد درخواست') 
    Title = models.CharField(max_length=500, verbose_name='عنوان مورد درخواست')  

    Request = models.ForeignKey(to='Request', verbose_name='شناسه درخواست مرتبط', 
                                on_delete=models.SET_NULL, null=True )     
    RequestItemStatus = models.ForeignKey(to='Status', verbose_name='وضعیت مورد درخواست', 
                                      on_delete=models.SET_NULL, null=True,limit_choices_to={"StatusType":"RI"})
    RequestItemKind = models.ForeignKey(to='Kind',limit_choices_to={"KindType":"RI"}, verbose_name='نوع مورد درخواست',
                                    on_delete=models.SET_NULL, null=True)
    Task = models.ForeignKey(to='Task', verbose_name='شناسه تسک مرتبط', 
                                on_delete=models.SET_NULL, null=True )        

    ToUser=models.CharField(max_length=100, null=True, blank=True, default=None, verbose_name='نام کاربری مجری مورد درخواست')
    ToUserNationalCode=models.CharField(max_length=10,null=True, verbose_name='کد ملی مجری مورد درخواست')
    FromUser=models.CharField(max_length=100, null=True, blank=True, default=None, verbose_name='نام کاربری کاربر تعریف کننده مورد درخواست')
    FromUserNationalCode=models.CharField(max_length=10, null=True,verbose_name='کد ملی کاربر تعریف کننده مورد درخواست')

    CreateDate = models.CharField(max_length=10, verbose_name='تاریخ ایجاد',
                                  help_text='تاریخ ایجاد مورد درخواست به شمسی و بدون ساعت است')
    

    class Meta:
        verbose_name='مورد درخواست'
        verbose_name_plural='موارد درخواست'

    def __str__(self):
        return self.Title    

class Task(models.Model):
    class Meta:
        verbose_name='تسک'
        verbose_name_plural='تسک ها'

    Id=models.CharField(max_length=10,primary_key=True, verbose_name='شناسه تسک',
                        help_text='در صورتی که تسک PM باشد شناسه به صورت P-Id و در صورتی که برای جیرا باشد J-Id است. در صورتی که تسک هم در جیرا و هم در PM باشد، شناسه PM در نظر گرفته می شود')
    IssueId=models.IntegerField(null=True, verbose_name='شناسه تسک در جیرا')
    TaskId=models.IntegerField(null=True, verbose_name='شناسه تسک در PM')
    Title=models.CharField(max_length=256,null=True,blank=True,verbose_name='عنوان تسک')

    TaskKind=models.ForeignKey(to='Kind',limit_choices_to={"KindType":"TA"}, verbose_name='نوع تسک', on_delete=models.SET_NULL, 
                               null=True,related_name='TaskKind')
    IssueKind=models.ForeignKey(to='Kind',limit_choices_to={"KindType":"IS"}, verbose_name='نوع تسک در جیرا', on_delete=models.SET_NULL, 
                                null=True, related_name='IssueKind')
    TaskStatus=models.ForeignKey(to='Status',limit_choices_to={"StatusType":"TA"} , verbose_name='وضعیت', on_delete=models.SET_NULL,
                                  related_name='TaskStatus', null=True)
    IssueStatus=models.ForeignKey(to='Status', verbose_name='وضعیت در جیرا', limit_choices_to={"StatusType":"IS"} ,on_delete=models.SET_NULL, 
                                  related_name='IssueStatus',null=True)
    IssueResolution = models.CharField(max_length=50, null=True, verbose_name='نتیجه انجام تسک',
                                       help_text='این مقدار فقط برای جیرا تعریف شده و چگونگی خاتمه تسک ها را مشخص می کند')

    TaskSprint=models.CharField(max_length=50,null=True,blank=True,verbose_name='ایتریشن تسک')
    TaskVersion=models.CharField(max_length=100,null=True,blank=True,verbose_name='نسخه تسک')

    ParentTask=models.ForeignKey('Task',null=True,on_delete=models.SET_NULL,related_name='ParentTasks',verbose_name='شناسه تسک مادر')
    RootTask=models.ForeignKey('Task',null=True,on_delete=models.SET_NULL,related_name='RootTasks',verbose_name='شناسه تسک اصلی')
    
    Project=models.ForeignKey(to='Project', verbose_name='پروژه تسک', on_delete=models.SET_NULL, null=True)
    TeamCode=models.ForeignKey(to='Team', verbose_name='تیم تسک', on_delete=models.SET_NULL, null=True, db_column='TeamCode')
    CorpCode=models.ForeignKey(to='Corp', verbose_name='شرکت درخواست دهنده', on_delete=models.SET_NULL, null=True, db_column='corpCode')

    MessageId=models.IntegerField(null=True, blank=True,verbose_name='شناسه پیام')
    Request = models.ForeignKey(to='Request', on_delete=models.SET_NULL, null=True, 
                                verbose_name='شناسه درخواست')
    RequestItem = models.ForeignKey(to='RequestItem', on_delete=models.SET_NULL, null=True, 
                                    verbose_name='شناسه مورد درخواست')

    ToUser=models.CharField(max_length=100, null=True, blank=True, default=None, verbose_name='نام کاربری مجری')
    ToUserNationalCode=models.CharField(max_length=10,null=True, verbose_name='کد ملی مجری')
    FromUser=models.CharField(max_length=100, null=True, blank=True, default=None, verbose_name='نام کاربری تعریف کننده تسک')
    FromUserNationalCode=models.CharField(max_length=10, null=True,verbose_name='کد ملی تعریف کننده تسک')

    CreateDate=models.CharField(max_length=20,null=True, blank=True,verbose_name='تاریخ و ساعت ایجاد',
                                    help_text='تاریخ به شمسی است و ساعت به آن اضافه شده است')
    EstimatedWorkHoursMinutes=models.IntegerField(verbose_name='ساعت تخمین به دقیقه', default=0)
    ActualWorkHoursMinutes=models.IntegerField(verbose_name='ساعت کارکرد به دقیقه', default=0)
    ActualEndDate=models.CharField(max_length=20,null=True, blank=True,verbose_name='تاریخ و ساعت پایان',
                                   help_text='تاریخ به شمسی است و ساعت به آن اضافه شده است')
    IsFinished=models.BooleanField(default=False,verbose_name='پایان یافته است؟')

    def __str__(self):
        return f'{self.Title} ({self.Id})'


class TaskCorps(models.Model):
    Task = models.ForeignKey(to='Task', verbose_name='شناسه تسک', on_delete=models.CASCADE)
    CorpCode=models.ForeignKey(to='Corp', verbose_name='شرکت درخواست دهنده', null=False,
                               on_delete=models.CASCADE, db_column='CorpCode')
    RequestItem = models.ForeignKey(to='RequestItem', verbose_name='شناسه مورد درخواست', 
                                    null=True, on_delete=models.SET_NULL)
    WorkHourMinutesReal = models.PositiveIntegerField(verbose_name='ساعت کارکرد واقعی', default=0)
    WorkHourMinutesPM = models.PositiveIntegerField(verbose_name='ساعت کارکرد ثبت شده در PM', default=0)
    WorkHourMinutesInvoice = models.PositiveIntegerField(verbose_name='ساعت کارکرد مندرج در صورت حساب', default=0)
    IsPrimaryRequester = models.BooleanField(verbose_name='درخواست دهنده اصلی بوده است؟', 
                                             default=False)


    class Meta:
        verbose_name='شرکت مرتبط با تسک'
        verbose_name_plural='شرکت های مرتبط با تسک ها'

    def __str__(self):
        return f'{self.Task} ({self.CorpCode})'

class TaskWorkhours(models.Model):
    WorkTimeDate = models.CharField(max_length=10, verbose_name='تاریخ ایجاد',
                                  help_text='تاریخ ایجاد مورد درخواست به شمسی و بدون ساعت است')
    RelatedUser=models.CharField(max_length=100, null=True, blank=True, default=None, verbose_name='نام کاربری مجری')
    RelatedUserNationalCode=models.CharField(max_length=10,null=True, verbose_name='کد ملی مجری')
    WorkHoursMinutes = models.PositiveIntegerField(verbose_name='کارکرد به دقیقه')
    Task = models.ForeignKey(to='Task', verbose_name='شناسه تسک مرتبط', 
                                on_delete=models.SET_NULL, null=True )        

    class Meta:
        verbose_name='کارکرد تسک'
        verbose_name_plural='کارکردهای تسک ها'

    def __str__(self):
        return  f'{self.WorkHoursMinutes} ({self.WorkTimeDate})'     
class EIT_View_Verion(models.Model):
    class Meta:
        verbose_name='نسخه'
        verbose_name_plural='نسخه ها'
        db_table='EIT_View_Verion'
        managed=False
    VersionNumber=models.CharField(max_length=5,primary_key=True)

    def __str__(self):
        return self.VersionNumber

class VOIP(models.Model):
    CallDate = models.DateTimeField(verbose_name='زمان تماس',null=True,
                    help_text='تاریخ به میلادی و ساعت')
    CallSource = models.CharField(max_length=50, verbose_name='تماس گیرنده',null=True,
                    help_text='شماره تماس گیرنده، می تواند با صفر شروع شود')
    CallDestination = models.CharField(max_length=50, verbose_name='شماره مقصد',null=True,
                    help_text='شماره مقصد. می تواند با صفر شروع شود')
    CallDivert = models.CharField(max_length=11, verbose_name='شماره انتقال تماس',null=True,
                    help_text='در صورتی که تماس منتقل شده باشد، شماره انتقالی که معمولا داخلی است')
    RingGroup = models.CharField(max_length=30, verbose_name='گروه بندی تماس',null=True,
                    help_text='مربوط به سیستم VOIP است')
    SourceChanel = models.CharField(max_length=50, verbose_name='کانال مبدا',null=True,
                    help_text='مربوط به سیستم VOIP است')
    DestinationChanel = models.CharField(max_length=50, verbose_name='کانال مقصد',null=True,
                    help_text='مربوط به سیستم VOIP است')
    AccountCode = models.CharField(max_length=50, verbose_name='شماره اکانت',null=True,
                    help_text='شماره اکانت مربوطه')
    CallStatus = models.CharField(max_length=15, verbose_name='وضعیت تماس',null=True,
                    help_text='مشخص می کند که تماس پاسخ داده شده، پاسخ داده نشده و یا رد شده است')
    Duration = models.PositiveBigIntegerField(verbose_name='مدت تماس',null=True,
                    help_text='مدت تماس بر حسب ثانیه')
    StringDuration = models.CharField(max_length=10, verbose_name='مدت تماس',null=True,
                    help_text='مدت زمان به صورت رشته ای MM:SS')
    InputCall = models.BooleanField(verbose_name='تماس ورودی',null=True,
                    help_text='اگر تماس ورودی باشد مقدار یک و در غیر این صورت صفر است')
    CorpCode = models.ForeignKey(to='Corp',on_delete=models.SET_NULL, verbose_name='کد شرکت',null=True,
                    help_text='کد شرکت', db_column='CorpCode')
    CorpName = models.CharField(max_length=20, verbose_name='نام شرکت',null=True,
                    help_text='نام شرکت')
    FromUserName = models.CharField(max_length=50, verbose_name='نام کاربر تماس گیرنده',null=True,
                    help_text='نام کاربر تماس گیرنده')
    FromUserRoleTypeCode = models.CharField(max_length=10, verbose_name='کد گروه سمت کاربر تماس گیرنده',null=True,
                    help_text='مشخص می کند که کاربر مربوطه، پشتیبان، برنامه نویس و ... است.')
    FromTeamCode = models.ForeignKey(to='Team',on_delete=models.SET_NULL,db_column='FromTeamCode' ,verbose_name='تیم کاربر تماس گیرنده',null=True,
                    help_text='کد تیم کاربر تماس گیرنده', related_name='FromTeamCode')
    ToUserName = models.CharField(max_length=50, verbose_name='کد کاربر مقصد',null=True,
                    help_text='شناسه کاربری که با او تماس گرفته شده است')
    ToTeamCode = models.ForeignKey(to='Team',on_delete=models.SET_NULL, db_column='ToTeamCode',verbose_name='تیم کاربر مقصد',null=True,
                    help_text='کد کاربری که با او تماس گرفته شده است', related_name='ToTeamCode')
    ToUserRoleTypeCode = models.CharField(max_length=10, verbose_name='کد گروه کاربر مقصد',null=True,
                    help_text='مشخص می کند که کاربر مربوطه، پشتیبان، برنامه نویس و ... است.')
    
    class Meta:
        verbose_name='سابقه تماس'
        verbose_name_plural='سوابق تماس ها'

    def __str__(self):
        return  f'{self.CallDate} - {self.CorpName} ({self.FromUserName} - {self.ToUserName})'             
    

class Userstel(models.Model):
    Tel = models.CharField(max_length=15, verbose_name="شماره تماس") 
    UserName = models.CharField(max_length=100, verbose_name="نام کاربری") 
    StartDate = models.CharField(max_length=10, verbose_name="تاریخ شروع") 
    EndDate = models.CharField(max_length=10, blank=True, null=True, verbose_name="تاریخ پایان") 
    StartDateMiladi = models.DateField(verbose_name="تاریخ شروع میلادی") 
    EndDateMiladi = models.DateField(blank=True, null=True, verbose_name="تاریخ پایان میلادی") 

    class Meta:
        verbose_name='شماره داخلی کاربر'
        verbose_name_plural='شماره های داخلی کاربران'

class Corptel(models.Model):
    CorpCode = models.ForeignKey(Corp, db_column="CorpCode", on_delete=models.CASCADE, verbose_name="شرکت") 
    TelNumber = models.CharField(max_length=15, verbose_name="شماره تماس") 

    class Meta:
        verbose_name='شماره شرکت بیمه '
        verbose_name_plural='شماره های شرکت های بیمه'


class VoipInvalidTellCount(models.Model):
    Tel = models.CharField(max_length=15, verbose_name="شماره تماس") 
    UserName = models.CharField(max_length=100, verbose_name="نام کاربری") 
    StartDate = models.CharField(max_length=10, verbose_name="تاریخ شروع") 
    EndDate = models.CharField(max_length=10, blank=True, null=True, verbose_name="تاریخ پایان") 
    StartDateMiladi = models.DateField(verbose_name="تاریخ شروع میلادی") 
    EndDateMiladi = models.DateField(blank=True, null=True, verbose_name="تاریخ پایان میلادی") 

    class Meta:
        managed = False
        db_table='EIT_VOIP_InvalidTelCount'
        verbose_name='شماره تماس ناشناس'
        verbose_name_plural='شماره تماس های ناشناس'

class VoipUnkownCaller(models.Model):
    CallNumber = models.CharField(max_length=15, verbose_name="شماره تماس") 
    CallCount = models.BigIntegerField() 

    class Meta:
        managed = False
        db_table = 'EIT_VOIP_UnkownCaller'
        verbose_name='شماره تماس غیرمجاز'
        verbose_name_plural='شماره تماس های غیر مجاز'