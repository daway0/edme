# Generated by Django 4.0.1 on 2023-08-19 11:42

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('EIT', '0010_alter_task_duedate_alter_task_estimatedbegindate_and_more'),
    ]

    operations = [
        migrations.AlterField(
            model_name='subsysteam',
            name='TeamCode',
            field=models.CharField(blank=True, default=None, max_length=10, null=True, verbose_name='تیم مربوطه'),
        ),
        migrations.AlterField(
            model_name='task',
            name='FromUser',
            field=models.CharField(blank=True, default=None, max_length=100, null=True, verbose_name='از کاربر'),
        ),
        migrations.AlterField(
            model_name='task',
            name='OwnerTask',
            field=models.CharField(blank=True, default=None, max_length=100, null=True, verbose_name='کاربرتسک'),
        ),
        migrations.AlterField(
            model_name='task',
            name='QCUser',
            field=models.CharField(blank=True, default=None, max_length=100, null=True, verbose_name=' کاربرQC '),
        ),
        migrations.AlterField(
            model_name='task',
            name='ToUser',
            field=models.CharField(blank=True, default=None, max_length=100, null=True, verbose_name='به کاربر'),
        ),
    ]
