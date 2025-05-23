# Generated by Django 4.0.1 on 2025-03-28 11:44

from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('EIT', '0044_alter_voip_duration'),
    ]

    operations = [
        migrations.AddField(
            model_name='corpversion',
            name='ApproveDate',
            field=models.CharField(blank=True, max_length=10, null=True, verbose_name='تاریخ تایید صورت حساب'),
        ),
        migrations.AddField(
            model_name='corpversion',
            name='InvoiceId',
            field=models.PositiveIntegerField(null=True, verbose_name='شناسه صورت حساب'),
        ),
        migrations.CreateModel(
            name='CorpInvoiceTask',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('FinalWorkHoursMiutes', models.PositiveIntegerField(verbose_name='ساعت کارکرد نهایی بر حسب دقیقه')),
                ('IsPrimaryRequestor', models.BooleanField(default=0, null=True, verbose_name='شرکت درخواست کننده اصلی بوده؟')),
                ('CorpVersion', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='EIT.corpversion', verbose_name='شناسه نسخه ')),
                ('Task', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='EIT.task', verbose_name='شناسه تسک ')),
            ],
            options={
                'verbose_name': 'تسک صورت حساب',
                'verbose_name_plural': 'تسک صورت حساب ها',
            },
        ),
    ]
