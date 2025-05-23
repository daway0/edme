# Generated by Django 4.0.1 on 2025-03-29 09:57

from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('EIT', '0049_rename_lastshcreatedate_conversation_lastmidifydate_and_more'),
    ]

    operations = [
        migrations.AddField(
            model_name='task',
            name='Request',
            field=models.ForeignKey(null=True, on_delete=django.db.models.deletion.SET_NULL, to='EIT.request', verbose_name='شناسه درخواست'),
        ),
        migrations.AddField(
            model_name='task',
            name='RequestItem',
            field=models.ForeignKey(null=True, on_delete=django.db.models.deletion.SET_NULL, to='EIT.requestitem', verbose_name='شناسه مورد درخواست'),
        ),
    ]
