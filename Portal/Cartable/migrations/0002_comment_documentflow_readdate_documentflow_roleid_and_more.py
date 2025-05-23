# Generated by Django 4.0.1 on 2024-10-14 08:55

from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('Cartable', '0001_initial'),
    ]

    operations = [
        migrations.CreateModel(
            name='Comment',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('CreateDate', models.DateTimeField(auto_now_add=True, null=True, verbose_name='تاریخ ایجاد')),
                ('ModifyDate', models.DateTimeField(auto_now=True, null=True, verbose_name='تاریخ ویرایش')),
                ('CreatorUserName', models.CharField(blank=True, default=None, max_length=100, null=True, verbose_name='ایجاد کننده')),
                ('ModifierUserName', models.CharField(blank=True, default=None, max_length=100, null=True, verbose_name='ویرایش کننده')),
                ('IsPublic', models.BooleanField(default=True, verbose_name='نظرعمومی است')),
                ('Comment', models.CharField(blank=True, max_length=4000, null=True, verbose_name='توضیحات')),
                ('Document', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.CASCADE, related_name='DocumentComments', to='Cartable.document', verbose_name='شناسه سند')),
            ],
        ),
        migrations.AddField(
            model_name='documentflow',
            name='ReadDate',
            field=models.DateTimeField(blank=True, null=True, verbose_name='زمان خوانده شده'),
        ),
        migrations.AddField(
            model_name='documentflow',
            name='RoleId',
            field=models.PositiveIntegerField(null=True, verbose_name='شناسه سمت'),
        ),
        migrations.AddField(
            model_name='documentflow',
            name='TeamCode',
            field=models.CharField(max_length=3, null=True, verbose_name='شناسه تیم'),
        ),
        migrations.AddField(
            model_name='documentflow',
            name='WorkFlowStep',
            field=models.PositiveSmallIntegerField(null=True, verbose_name='مرحله'),
        ),
        migrations.CreateModel(
            name='CommentTargetUser',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('TargetUser', models.CharField(max_length=300, verbose_name='مخاطب')),
                ('CommentId', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='Cartable.comment')),
            ],
        ),
        migrations.AddField(
            model_name='comment',
            name='DocumentFlow',
            field=models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.CASCADE, related_name='DocumentFlowComments', to='Cartable.documentflow', verbose_name='شناسه مرحله'),
        ),
    ]
