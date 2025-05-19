import requests

from Utility import configs

from shared_lib import core as slcore

def v1(doc_id):
    url = configs.FAILED_FINISH_FLOW("MAIN_SERVER", doc_id)
    response = requests.post(url,headers={"Service-Authorization":slcore.generate_token("e.rezaee")})
    response.raise_for_status()