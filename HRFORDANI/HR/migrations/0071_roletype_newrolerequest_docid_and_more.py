# Generated by Django 5.0.12 on 2025-05-12 17:06

import django.db.models.deletion
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('HR', '0070_newrolerequest_conditionstext_and_more'),
    ]

    operations = [
        migrations.CreateModel(
            name='RoleType',
            fields=[
                ('TypeCode', models.CharField(max_length=1, primary_key=True, serialize=False)),
                ('TypeTitle', models.CharField(max_length=200)),
            ],
            options={
                'verbose_name': 'نوع سمت',
                'verbose_name_plural': 'نوع سمت ها',
                'db_table': 'HR_RoleType',
            },
        ),
        migrations.AddField(
            model_name='newrolerequest',
            name='DocId',
            field=models.IntegerField(blank=True, null=True, verbose_name='شناسه سند'),
        ),
        migrations.AddField(
            model_name='newrolerequest',
            name='ManagerType',
            field=models.ForeignKey(null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='as_manager_type', to='HR.constvalue', verbose_name='مدیر مربوطه'),
        ),
        migrations.AddField(
            model_name='newrolerequest',
            name='NewRoleTypeTitle',
            field=models.CharField(max_length=100, null=True, verbose_name='عنوان نوع سمت جدید'),
        ),
        migrations.AddField(
            model_name='newrolerequest',
            name='RoleType',
            field=models.ForeignKey(null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='as_role_type', to='HR.constvalue', verbose_name='کد نوع سمت'),
        ),
        migrations.AddField(
            model_name='role',
            name='ManagerType',
            field=models.CharField(max_length=100, null=True, verbose_name='مدیر مربوطه'),
        ),
        migrations.AddField(
            model_name='role',
            name='RoleType',
            field=models.CharField(max_length=100, null=True, verbose_name='کد نوع سمت'),
        ),
    ]
