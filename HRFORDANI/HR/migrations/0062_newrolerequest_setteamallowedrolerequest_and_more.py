# Generated by Django 4.0.1 on 2025-01-24 10:09

import HR.validator
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('HR', '0061_remove_educationhistory_degreetype_and_more'),
    ]

    operations = [
        migrations.CreateModel(
            name='NewRoleRequest',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('RoleTitle', models.CharField(max_length=100, verbose_name='عنوان سمت')),
                ('HasLevel', models.BooleanField(default=False, verbose_name='آیا این سمت دارای سطح است؟')),
                ('HasSuperior', models.BooleanField(default=False, verbose_name='آیا این سمت دارای ارشد دارد؟')),
                ('AllowedTeams', models.CharField(max_length=1000, verbose_name='این سمت در چه تیم های فعال است؟')),
                ('RequestorId', models.CharField(max_length=10, validators=[HR.validator.Validator.NationalCode_Validator], verbose_name='کد ملی درخواست دهنده')),
                ('RequestDate', models.DateField(auto_now_add=True, verbose_name='تاریخ ارائه درخواست')),
                ('ManagerId', models.CharField(max_length=10, validators=[HR.validator.Validator.NationalCode_Validator], verbose_name='کد ملی مدیر درخواست دهنده')),
                ('ManagerOpinion', models.BooleanField(default=0, help_text='در صورت موافقت مقدار یک و در غیر این صورت صفر می باشد', verbose_name='نظر مدیر درخواست دهنده')),
                ('ManagerDate', models.DateField(null=True, verbose_name='تاریخ اظهار نظر مدیر درخواست دهنده')),
                ('CTOId', models.CharField(max_length=10, null=True, validators=[HR.validator.Validator.NationalCode_Validator], verbose_name='کد ملی مدیر عامل')),
                ('CTOOpinion', models.BooleanField(default=0, help_text='در صورت موافقت مقدار یک و در غیر این صورت صفر می باشد', null=True, verbose_name='نظر مدیر عامل')),
                ('CTODate', models.DateField(verbose_name='تاریخ اظهار نظر مدیرعامل')),
            ],
            options={
                'verbose_name': 'درخواست افزودن سمت جدید',
                'verbose_name_plural': 'درخواست افزودن سمت های جدید',
            },
        ),
        migrations.CreateModel(
            name='SetTeamAllowedRoleRequest',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('TeamAllowedRoles', models.CharField(max_length=2000, verbose_name='اطلاعات تیم و سمت های مجاز')),
                ('RequestorId', models.CharField(max_length=10, validators=[HR.validator.Validator.NationalCode_Validator], verbose_name='کد ملی درخواست دهنده')),
                ('RequestDate', models.DateField(auto_now_add=True, verbose_name='تاریخ ارائه درخواست')),
                ('ManagerId', models.CharField(max_length=10, validators=[HR.validator.Validator.NationalCode_Validator], verbose_name='کد ملی مدیر درخواست دهنده')),
                ('ManagerOpinion', models.BooleanField(default=0, help_text='در صورت موافقت مقدار یک و در غیر این صورت صفر می باشد', verbose_name='نظر مدیر درخواست دهنده')),
                ('ManagerDate', models.DateField(null=True, verbose_name='تاریخ اظهار نظر مدیر درخواست دهنده')),
                ('CTOId', models.CharField(max_length=10, validators=[HR.validator.Validator.NationalCode_Validator], verbose_name='کد ملی مدیر عامل')),
                ('CTOOpinion', models.BooleanField(default=0, help_text='در صورت موافقت مقدار یک و در غیر این صورت صفر می باشد', null=True, verbose_name='نظر مدیر عامل')),
                ('CTODate', models.DateField(verbose_name='تاریخ اظهار نظر مدیرعامل')),
            ],
            options={
                'verbose_name': 'درخواست تغییرات سمت های مجاز تیم',
                'verbose_name_plural': 'درخواست های تغییرات سمت های مجاز تیم ها',
            },
        ),
        migrations.AddField(
            model_name='role',
            name='Comment',
            field=models.CharField(max_length=200, null=True, verbose_name='توضیحات'),
        ),
        migrations.AddField(
            model_name='role',
            name='NewRoleRequest',
            field=models.ForeignKey(null=True, on_delete=django.db.models.deletion.SET_NULL, to='HR.newrolerequest', verbose_name='شناسه درخواست اضافه کردن سمت'),
        ),
    ]
