from django.urls import path
from . import views as v
#from HR.backends import check_auth_user,show_403
from Cartable.api import (
    GetDocument,
    GetDocumentExtra,
    CreateDocument,
    GetDocumentFlowByDocId,
    CreateDocumentFlow,
    UpdateDocument,
    GetDocumentFlowByOwner,
    GetDocumentFlow,
    UpdateDocumentFlow,
    CreateDocumentFlowBulk,
    GetDocumentFlowUnread,
    GetDocumentFlowEx,
    UpdateDocumentCustom,
    GetAllVisibeCartable,
    GetOfficeReceiveDate,
    GetDocumentLAstUserInCartable,
    Document2,
    ReadDocumentFlow,
    DocumentFlow2,
    document_flow_details,
    comments
)

app_name = "Cartable"

urlpatterns = [
    path('MyCartable/', v.my_cartable, name='my_cartable'),
    path('MyCartableAjax/',v.my_cartable_ajax, name="my_cartable_ajax"),
    path('DocFlowSSE/',v.doc_flow_sse, name="doc_flow_sse"),
    path('ExitFromCartable/<int:id>/', v.exit_from_cartable, name="exit_from_cartable"),
    path('WorkFlow/<int:doc_id>/', v.workflow_visual, name="workflow_visual"),


    # urls for api
    path('api/get-document/<str:by>/<str:id>/', GetDocument.as_view(), name='get_document'),
    path('api/get-document-extra/<str:id>/<str:app_code>/', GetDocumentExtra.as_view(), name='get_document_extra'),
    path('api/create-document/', CreateDocument.as_view(), name='create_document'),
    path('api/update-document/<int:id>/', UpdateDocument.as_view(), name='update_document'),
    path('api/update-document-custom/', UpdateDocumentCustom.as_view(), name='update_document_custom'),

    path('api/get-document-flow-by-docid/', GetDocumentFlowByDocId.as_view(), name='get_document_by_doc_id'),
    path('api/get-document-flow/', GetDocumentFlow.as_view(), name='get_document_flow'),
    path('api/get-document-flow-ex/', GetDocumentFlowEx.as_view(), name='get_document_flow_ex'),
    path('api/get-document-flow-unread/', GetDocumentFlowUnread.as_view(), name='get_document_flow_unread'),
    path('api/get-document-flow-by-owner/', GetDocumentFlowByOwner.as_view(), name='get_document_by_owner'),
    path('api/create-document-flow/', CreateDocumentFlow.as_view(), name='create_document_flow'),
    path('api/update-document-flow/<int:doc_flow_id>/', UpdateDocumentFlow.as_view(), name='update_document_flow'),
    path('api/create-document-flow-bulk/', CreateDocumentFlowBulk.as_view(), name='create_document_flow_bulk'),
    path('api/get-all-visible/', GetAllVisibeCartable.as_view(), name='get_all_visible'),
    path('api/get-office-receive-date/', GetOfficeReceiveDate.as_view(), name='get-office-receive-date'),
    path('api/get-document-last-user-incartable/', GetDocumentLAstUserInCartable.as_view(), name='get_document_last_user_incartable'),




    path('api/v1/documents/',Document2.as_view()),
    path('api/v1/document-flows/',DocumentFlow2.as_view()),
    path('api/v1/<int:doc_flow_id>/read/', ReadDocumentFlow.as_view(), name="ReadDocFlow")
,

    path('api/v1/document-flows-details/<int:doc_id>/',document_flow_details, name="document_flow_details"),
    path('api/v1/comments/', comments, name="comments"),
]