# Generated by Django 4.2.20 on 2025-04-03 19:21

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('EIT', '0070_alter_corpinvoicetask_task_and_more'),
    ]

    operations = [
        migrations.AlterField(
            model_name='corpversion',
            name='SendDate',
            field=models.CharField(max_length=10, null=True, verbose_name='تاریخ ارسال نسخه'),
        ),
    ]
