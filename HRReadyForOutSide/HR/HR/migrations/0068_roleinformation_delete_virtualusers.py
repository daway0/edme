# Generated by Django 5.0.12 on 2025-04-25 16:19

import django.db.models.deletion
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('HR', '0067_rename_personnationlcode_postaladdress_personnationalcode_and_more'),
    ]

    operations = [
        migrations.CreateModel(
            name='RoleInformation',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('DescriptionType', models.CharField(choices=[('C', 'شرایط احراز'), ('D', 'شرح وظایف')], max_length=1, verbose_name='نوع')),
                ('RoleID', models.ForeignKey(db_column='RoleID', on_delete=django.db.models.deletion.CASCADE, to='HR.role', verbose_name='شناسه سمت')),
            ],
            options={
                'verbose_name': 'دسته بندی سمت',
                'verbose_name_plural': 'دسته بندی های سمت',
            },
        ),
        migrations.DeleteModel(
            name='VirtualUsers',
        ),
    ]
