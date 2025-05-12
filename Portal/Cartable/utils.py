import traceback
from django.core.cache import cache
import json
import requests
from Utility.Authentication.Helper import V1_get_host_from_server
from threading import Thread
from django.core.mail import EmailMessage
from shared_lib import core as slcore

def get_all_users():
    if "all_users_catch" in cache:
        return json.loads(cache.get('all_users_catch'))
    try:
        url = f"{V1_get_host_from_server()}:14000/HR/api/all-users/"
        response = requests.get(url)
        data = response.json().get('data')
        cache.set('all_users_catch', json.dumps(data))
        return data
    except:
        traceback.print_exc()


def get_all_active_users():
    if "all_active_users" in cache:
        return json.loads(cache.get('all_active_users'))
    try:
        url = f'{V1_get_host_from_server()}:14000/HR/api/get-user-team-roles/'
        response = requests.get(url, headers={"Service-Authorization":slcore.generate_token("e.rezaee")})
        data = response.json().get('data')
        cache.set('all_active_users',json.dumps(data))
        return data
    except:
        traceback.print_exc()


def send_email_notif(
    subject: str,
    message: str,
    emails: list[str],
    max_tries: int = 2,
):
    email_thread = Thread(
        target=_send_mail,
        args=(subject, message, emails, max_tries),
    )
    email_thread.start()


def _send_mail(
    subject: str,
    message: str,
    emails: list[str],
    max_tries: int,
):
    email = EmailMessage(
        subject=subject, body=message, to=emails, bcc=[settings.EMAIL_HOST_USER], from_email=settings.EMAIL_HOST_USER
    )
    email.content_subtype = "html"

    total_tries = 0
    success = 0
    while success == 0:
        try:
            success = email.send()
        except Exception as e:
            total_tries += 1

            if total_tries >= max_tries:
                break