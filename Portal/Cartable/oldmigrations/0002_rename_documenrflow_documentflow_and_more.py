# Generated by Django 4.0.1 on 2022-03-06 05:29

from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        #('AccessControl', '__first__'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ('Cartable', '0001_initial'),
    ]

    operations = [
        migrations.RenameModel(
            old_name='DocumenrFlow',
            new_name='DocumentFlow',
        ),
        # migrations.RemoveField(
        #     model_name='document',
        #     name='AppURLId',
        # ),
        migrations.AddField(
            model_name='document',
            name='AppCode',
            field=models.CharField(max_length=100,blank=True,  null=True, verbose_name='مسیر برنامه'),
        ),
        # migrations.AlterField(
        #     model_name='document',
        #     name='AppCode_id',
        #     field=models.CharField(blank=True, max_length=200, null=True, verbose_name='مسیر برنامه'),
        # ),
    ]
