# Generated by Django 3.2.9 on 2021-12-13 07:36

from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        ('HR', '__first__'),
    ]

    operations = [
        migrations.CreateModel(
            name='App',
            fields=[
                ('Code', models.CharField(db_column='Code', max_length=6, primary_key=True, serialize=False, verbose_name='کد')),
                ('Title', models.CharField(max_length=100, verbose_name='عنوان')),
            ],
        ),
        migrations.CreateModel(
            name='Permission',
            fields=[
                ('Code', models.CharField(db_column='Code', max_length=10, primary_key=True, serialize=False, verbose_name='کد')),
                ('Title', models.CharField(max_length=100, verbose_name='عنوان')),
                ('PermissionType', models.CharField(choices=[('V', 'مجوز مشاهده'), ('E', 'مجوز ویرایش'), ('A', 'دسترسی کامل')], max_length=1, verbose_name='نوع مجوز')),
                ('AppCode', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='AccessControl.app', verbose_name='کد برنامه')),
            ],
        ),
        migrations.CreateModel(
            name='PermissionGroup',
            fields=[
                ('Code', models.IntegerField(primary_key=True, serialize=False, verbose_name='کد')),
                ('Title', models.CharField(max_length=100, verbose_name='شرح')),
            ],
        ),
        migrations.CreateModel(
            name='PermissionVariable',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('Code', models.CharField(max_length=5, verbose_name='کد')),
                ('Title', models.CharField(max_length=100, verbose_name='عنوان')),
                ('VariableDescription', models.CharField(max_length=200, verbose_name='شرح')),
            ],
        ),
        migrations.CreateModel(
            name='System',
            fields=[
                ('Code', models.CharField(db_column='Code', max_length=3, primary_key=True, serialize=False, verbose_name='کد')),
                ('Title', models.CharField(max_length=100, verbose_name='عنوان')),
                ('PortNumber', models.IntegerField(verbose_name='پورت')),
            ],
        ),
        migrations.CreateModel(
            name='UserRoleGroupPermission',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('OwnerPermissionGroup', models.ForeignKey(db_column='OwnerPermissionGroup', on_delete=django.db.models.deletion.CASCADE, to='AccessControl.permissiongroup', verbose_name='تیم')),
                ('OwnerPermissionRole', models.ForeignKey(db_column='OwnerPermissionRole', db_constraint=False, on_delete=django.db.models.deletion.CASCADE, to='HR.role', verbose_name='سمت')),
                ('OwnerPermissionUser', models.ForeignKey(db_column='OwnerPermissionUser', db_constraint=False, on_delete=django.db.models.deletion.CASCADE, to='HR.users', verbose_name='کاربر')),
                ('PermissionCode', models.ForeignKey(db_column='PermissionCode', on_delete=django.db.models.deletion.CASCADE, to='AccessControl.permission', verbose_name='کددسترسی')),
            ],
        ),
        migrations.CreateModel(
            name='AppURL',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('URL', models.CharField(max_length=500, verbose_name='مسیر دسترسی')),
                ('AppCode', models.ForeignKey(db_column='AppCode', on_delete=django.db.models.deletion.CASCADE, to='AccessControl.app', verbose_name='کد')),
            ],
        ),
        migrations.CreateModel(
            name='AppPermissionType',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('PermissionType', models.CharField(max_length=100)),
                ('AppCode', models.ForeignKey(db_column='AppCode', on_delete=django.db.models.deletion.CASCADE, to='AccessControl.app', verbose_name='کد برنامه')),
            ],
        ),
        migrations.AddField(
            model_name='app',
            name='SystemCode',
            field=models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='AccessControl.system', verbose_name='کدسیستم'),
        ),
    ]
