from django.contrib.auth.backends import RemoteUserBackend

class CustomRemoteUserBackend(RemoteUserBackend):
    create_unknown_user = False
    domain_name = "EIT\\"

    def clean_username(self, username):
        """Removing Domain name (EIT) from username."""
        return username.replace(self.domain_name, "")
