# Generated by Django 4.0.1 on 2022-05-30 13:49

from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('AccessControl', '0020_variablevaluerelated_remove_appurl_ispublic_and_more'),
    ]

    operations = [
        migrations.RemoveField(
            model_name='permissionvariablevalue',
            name='VariableValue',
        ),
        migrations.AddField(
            model_name='permissionvariablevalue',
            name='VariableValue',
            field=models.ForeignKey(null=True, on_delete=django.db.models.deletion.CASCADE, to='AccessControl.variablevaluerelated', verbose_name='مقدار متغیر'),
        ),
    ]
