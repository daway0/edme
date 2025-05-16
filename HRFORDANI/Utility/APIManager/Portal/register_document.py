

import requests

from Utility import configs

from shared_lib import core as slcore

def v1(app_doc_id: int, priority: str, doc_state: str, document_title: str, app_code: str, owner: str) -> dict:
    url = configs.PUT_DOCUMENT("MAIN_SERVER")

    json_data = {
        "AppDocId": app_doc_id,
        "Priority": priority,
        "DocState": doc_state,
        "DocumentTitle": document_title,
        "AppCode": app_code,
        "DocumentOwner": owner,
    }
    r = requests.put(url, json_data, headers={"Service-Authorization":slcore.generate_token("e.rezaee")})
    if r.status_code == 200:
        return r.json()
    return r.json()


def v2(
    app_doc_id: int,
    priority: str,
    doc_state: str,
    document_title: str,
    app_code: str,
    owner_nationalcode: str
) -> dict:
    """using NationalCode"""

    url = configs.PUT_DOCUMENT_NATIONAL_CODE("MAIN_SERVER")

    json_data = {
        "AppDocId": app_doc_id,
        "Priority": priority,
        "DocState": doc_state,
        "DocumentTitle": document_title,
        "AppCode": app_code,
        "DocumentOwnerNationalCode": owner_nationalcode,
    }
    r = requests.put(url, json=json_data, headers={"Service-Authorization":slcore.generate_token("e.rezaee")})
    if r.status_code == 200:
        return r.json()
    return r.json()

