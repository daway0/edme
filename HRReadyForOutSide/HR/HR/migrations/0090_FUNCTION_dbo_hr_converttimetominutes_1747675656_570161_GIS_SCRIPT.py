# Generated by Erfan Rezaee on 19 مه 2025، ساعت 20:57

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('HR', '0089_FUNCTION_dbo_getalluserteamrole_1747675656_535424_GIS_SCRIPT'),
    ]

    with open("HR/SQLScripts/[dbo].[hr_converttimetominutes]1747675656.570161.sql", "r", encoding="utf-8") as f:
        sql = f.read()
    operations = [
        migrations.RunSQL(
            sql=sql,
            reverse_sql="DROP FUNCTION [dbo].[hr_converttimetominutes]"
        )
    ]
