# Generated by Django 4.0.1 on 2023-08-19 11:45

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('EIT', '0011_alter_subsysteam_teamcode_alter_task_fromuser_and_more'),
    ]

    operations = [
        migrations.AddField(
            model_name='feature',
            name='LevelNumber',
            field=models.IntegerField(default=0),
        ),
        migrations.AddField(
            model_name='feature',
            name='ParentHierarchy',
            field=models.CharField(blank=True, default='', max_length=500, null=True),
        ),
    ]
