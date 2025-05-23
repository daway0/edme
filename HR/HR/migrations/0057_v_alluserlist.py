# Generated by Django 4.0.1 on 2023-09-28 11:40

import HR.validator
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('HR', '0056_paymentaverage_paymentaverageyearly_and_more'),
    ]

    operations = [
        migrations.CreateModel(
            name='V_AllUserList',
            fields=[
                ('UserName', models.CharField(max_length=100, primary_key=True, serialize=False, verbose_name='نام کاربری')),
                ('FirstName', models.CharField(max_length=200, verbose_name='نام')),
                ('LastName', models.CharField(max_length=200, verbose_name='نام خانوادگی')),
                ('ContractDate', models.DateField(blank=True, null=True, verbose_name='تاریخ شروع همکاری')),
                ('NationalCode', models.CharField(blank=True, max_length=10, null=True, unique=True, validators=[HR.validator.Validator.NationalCode_Validator], verbose_name='کد ملی')),
                ('TeamName', models.CharField(max_length=100, verbose_name='نام تیم')),
                ('RoleName', models.CharField(max_length=100, verbose_name='عنوان سمت')),
                ('UserActive', models.BooleanField(default=True, verbose_name='کاربر فعال است؟')),
                ('RoleActive', models.BooleanField(default=True, verbose_name='سمت کاربر فعال است؟')),
            ],
            options={
                'db_table': 'V_AllUserList',
                'managed': False,
            },
        ),
    ]
