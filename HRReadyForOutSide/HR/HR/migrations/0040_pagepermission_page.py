# Generated by Django 4.0.1 on 2022-07-01 14:55

from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('HR', '0039_remove_pagepermission_pagename'),
    ]

    operations = [
        migrations.AddField(
            model_name='pagepermission',
            name='Page',
            field=models.ForeignKey(null=True, on_delete=django.db.models.deletion.CASCADE, to='HR.pageinformation', verbose_name='نام صفحه'),
        ),
    ]
