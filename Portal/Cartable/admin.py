from django.contrib import admin
from .models import Document,DocumentFlow


@admin.register(Document)
class DocumentAdmin(admin.ModelAdmin):
    list_display = ['AppDocId',
'Priority',
'DocState',
'DocumentTitle',
'AppCode']
    class Meta:
        model = Document



#admin.site.register(DocumentFlow)
@admin.register(DocumentFlow)
class DocumentFlowAdmin(admin.ModelAdmin):
    list_display = [
        'DocumentId',
        'InboxOwner',
        'SenderUser',
        'IsVisible',
    ]
    # list_display = ['DocumentId','InboxOwner_custom','SenderUser_custom']
    #
    # @admin.display(description="فرستنده")
    # def SenderUser_custom(self,obj):
    #     return obj.SenderUser.FullName
    #
    # @admin.display(description="گیرنده")
    # def InboxOwner_custom(self,obj):
    #     return obj.InboxOwner.FullName

    class Meta:
        model = DocumentFlow
