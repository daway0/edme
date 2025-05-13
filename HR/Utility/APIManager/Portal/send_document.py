"""This module is using for **begin the process of sending document
to others' cartable**

"""
import requests

from Utility import configs
from shared_lib import core as slcore

def ver1(doc_id: int, sender: str, inbox_owners: list[str]) -> dict:
    """ *Using Portal API v1*

    :param doc_id: Document Id
    :type doc_id: int
    :param sender: From *It must be Username(with @eit format)*
    :type sender: str
    :param inbox_owners: To *It must be Username(with @eit format)*
    :type inbox_owners: list[str]
    :return: Dictionary that contains DocumentFlow data if it created properly, Otherwise it contains validations error messages
    :rtype: dict
    """

    url = configs.PUT_DOCUMENT_FLOW("MAIN_SERVER")
    receive_status = {}
    for receiver in inbox_owners:
        json_data = {
            "DocumentId": doc_id,
            "InboxOwner": receiver,
            "SenderUser": sender
        }
        r = requests.put(url, json=json_data, headers={"Service-Authorization":slcore.generate_token("e.rezaee"), "Content-Type":"application/json"})
        receive_status[receiver] = r.json()
    return receive_status

# todo response payload must be implemented

def ver1plus(doc_id: int, sender: str, inbox_owners: list[dict]) -> dict:
    """ also send teamcode and roleid
    """

    url = configs.PUT_DOCUMENT_FLOW("MAIN_SERVER")
    receive_status = {}
    for personnel in inbox_owners:
        json_data = {
            "DocumentId": doc_id,
            "InboxOwner": personnel["username"],
            "SenderUser": sender,
            "TeamCode":personnel.get("team_code"),
            "RoleId":personnel.get("role_id"),
        }
        r = requests.put(url, json=json_data, headers={"Service-Authorization":slcore.generate_token("e.rezaee"), "Content-Type":"application/json"})
        receive_status[personnel["username"]] = r.json()
    return receive_status

def ver2(
    doc_id: int,
    sender_national_code: str = "1111111111",
    inbox_owners_national_code: list[str] = ["2222222222","3333333333"],
) -> dict:
    ... 