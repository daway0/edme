from django.core.exceptions import PermissionDenied
from functools import wraps
from django.http import HttpResponseRedirect
from django.shortcuts import render
from django.shortcuts import redirect


def put_ad_user_to_request(function):
    @wraps(function)
    def wrap(request, *args, **kwargs):
        username = kwargs.get('username')
        if "@eit" not in username:
            old_url = request.get_full_path()
            new_username = username+"@eit"
            new_url = old_url.replace(username,new_username)
            return redirect(new_url)

        for path in request.get_full_path().split("/"):
            if "." in path and "@" in path and "eit" in path and "@eit" in path:
                if "active_directory_user" in request.session:
                    del request.session['active_directory_user']
                request.session['active_directory_user'] = username
                break

        return function(request, *args, **kwargs)

    return wrap
