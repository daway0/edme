from django.db import models
from django.contrib.auth import models as django_auth_models

class EmptyUserTeamRole(Exception):
    ...


class User(django_auth_models.AbstractUser):
    national_code = models.CharField(max_length=10, unique=True, primary_key=True)
    team_roles = models.JSONField(null=True)
    gender = models.BooleanField(default=True, null=True)


    @property
    def fullname(self):
        return self.get_full_name()

    
    def team_manager(self, teamcode=None):
        if not self.team_roles:
            raise EmptyUserTeamRole
        
        managers_national_id = [] 
        for team_role in self.team_roles:
            if teamcode and team_role.get("TeamCode") != teamcode:
                continue
            managers_national_id.append(team_role.get("ManagerNationalCode"))
        return User.objects.filter(national_id__in=managers_national_id)
                
        
        

        
    


