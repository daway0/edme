# Generated by Django 4.0.1 on 2022-03-12 07:10

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('HR', '0018_v_hr_roletarget'),
    ]

    operations = [
        migrations.CreateModel(
            name='V_RoleTeam',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
            ],
            options={
                'verbose_name': 'سمت موجودر تیم',
                'verbose_name_plural': 'سمت های موجوددر تیم',
                'db_table': 'V_RoleTeam',
                'managed': False,
            },
        ),
        migrations.AlterField(
            model_name='users',
            name='AuthLoginDate',
            field=models.CharField(default=None, max_length=100, null=True),
        ),
    ]
