
from django.db import models
from Utility.Authentication.Utils import V1_get_api_fetch_data, os



class SystemCategory(models.Model):
    # UserName = models.ForeignKey(HRMODEL.Users, related_name='SystemCategoryUserNames', null=True, blank=True,
    #                              db_constraint=False, on_delete=models.CASCADE, verbose_name='نام کاربر')
    # HR.Users
    # UserName نداره دیفالت باشه
    UserName = models.CharField(max_length=100, null=True, blank=True, verbose_name='نام کاربر',default=None)
    Title = models.CharField(max_length=500, verbose_name='نام دسته بندی')
    Parent = models.ForeignKey('SystemCategory', related_name='SystemCategoryParents', null=True, blank=True,
                               on_delete=models.CASCADE, verbose_name='نام دسته بندی پدر',default=None)
    Icon = models.ImageField(upload_to='media/', verbose_name='ایکون', null=True, blank=True)
    OrderNumber = models.IntegerField(verbose_name='ترتیب', null=True, blank=True)

    def __str__(self):
        return self.Title

    @property
    def Level(self):
        ParentId = self.Parent_id
        ParentExist = SystemCategory.objects.filter(id=ParentId).count()
        Level = 0
        while ParentExist > 0:
            Level = Level + 1
            QS = SystemCategory.objects.get(id=ParentId)
            ParentId = QS.Parent_id
            ParentExist = SystemCategory.objects.filter(id=ParentId).count()
        return Level

    def PermittedURLCount(self, UserName):
        pass

    # یوزرنیم میگیره میگه
    @property
    def HasURL(self):
        HasURL = True if SystemCategoryURL.objects.filter(SystemCategory=self.id).exists() else False
        return HasURL

    @property
    def RelatedURL(self):
        RelatedURL = SystemCategoryURL.objects.filter(SystemCategory=self.id).first()
        if RelatedURL:
            app_url_id = RelatedURL.AppURL
            host = os.getenv('ACCESSCONTROL_ADDRESS_IP_PORT')
            app_code = V1_get_api_fetch_data(f"{host}AccessControl/api/get-app-url/{app_url_id}/", 'AppCode')
            URL = V1_get_api_fetch_data(f"{host}AccessControl/api/get-app-url/{app_url_id}/", 'URL')
            system_code = V1_get_api_fetch_data(f"{host}AccessControl/api/get-app-by-appcode/{app_code}/", 'SystemCode')
            server_id = V1_get_api_fetch_data(f"{host}AccessControl/api/get-system/{system_code}/", 'Server')
            port_number = V1_get_api_fetch_data(f"{host}AccessControl/api/get-server/{server_id}/", 'PortNumber')
            base_url = V1_get_api_fetch_data(f"{host}AccessControl/api/get-server/{server_id}/", 'IPAddress')
            full_url = base_url + ':' + str(port_number) + '/' + URL

            return full_url
        return ''


class SystemCategoryURL(models.Model):
    AppURL = models.BigIntegerField(null=True)
    SystemCategory = models.ForeignKey('SystemCategory', related_name='SystemCategoryURLSystemCategorys', null=True,
                                       blank=True, db_constraint=False, on_delete=models.CASCADE,
                                       verbose_name='دسته بندی برنامه',default=None)


