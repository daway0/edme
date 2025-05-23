# Generated by Django 4.0.1 on 2025-03-29 11:44

from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('EIT', '0051_constvalue'),
    ]

    operations = [
        migrations.CreateModel(
            name='VersionRequest',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('Title', models.CharField(max_length=500, verbose_name='عنوان نسخه ارسالی')),
                ('CreateDate', models.CharField(help_text='تاریخ به شمسی در قالب YYYY/MM/DD', max_length=10, verbose_name='تاریخ ایجاد نسخه')),
                ('SendDate', models.CharField(help_text='تاریخ به شمسی در قالب YYYY/MM/DD', max_length=10, verbose_name='تاریخ ارسال')),
                ('SendTime', models.TimeField(verbose_name='زمان ارسال نسخه')),
                ('CorpCode', models.ForeignKey(db_column='CorpCode', on_delete=django.db.models.deletion.CASCADE, to='EIT.corp', verbose_name='شرکت مربوطه')),
                ('VersionNumber', models.ForeignKey(db_column='VersionNumber', on_delete=django.db.models.deletion.CASCADE, to='EIT.version', verbose_name='شماره نسخه')),
                ('VersionTaskKind', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='EIT.constvalue', verbose_name='نوع نسخه')),
            ],
            options={
                'verbose_name': 'درخواست نسخه',
                'verbose_name_plural': 'درخواست نسخه ها',
            },
        ),
    ]
