# Generated by Django 4.0.1 on 2023-01-20 15:09

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('HR', '0051_rename_degree_type_users_degreetype_and_more'),
    ]

    operations = [
        migrations.RemoveField(
            model_name='users',
            name='Address',
        ),
    ]
