# Generated by Django 3.2.9 on 2021-12-20 11:27

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('EIT', '0001_initial'),
    ]

    operations = [
        migrations.CreateModel(
            name='EIT_View_Feature_Leaf',
            fields=[
                ('Code', models.IntegerField(db_column='Code', primary_key=True, serialize=False, verbose_name='کد')),
                ('FullTitle', models.CharField(blank=True, max_length=4000, null=True, verbose_name='نام کامل')),
            ],
            options={
                'verbose_name': 'ویژگی',
                'verbose_name_plural': 'ویژگی ها',
                'db_table': 'EIT_View_Feature_Leaf',
                'managed': False,
            },
        ),
    ]
