from pathlib import Path
from datetime import datetime
from django.core.management.base import BaseCommand
from django.template import Template, Context


def st_word(line, st:int):
    stripped = line.strip()
    if not stripped:
        return ""
    return stripped.split()[st].lower()


def get_latest_migration():
    # Convert to Path object for easier handling
    dir_path = Path("HR/migrations")
    
    # Check if directory exists
    if not dir_path.exists() or not dir_path.is_dir():
        return None
    
    # Pattern for Django migration files (e.g., 0001_initial.py, 0002_auto_20230515_1234.py)
    migration_files = [
        f for f in dir_path.iterdir() 
        if f.is_file() and f.suffix == '.py' and f.name != '__init__.py' 
        and f.name[:4].isdigit()
    ]
    
    if not migration_files:
        return None
    
    # Sort by migration number (first 4 digits)
    latest_migration = max(migration_files, key=lambda x: x.name[:4])
    
    return latest_migration.name

def latest_counter(filename):
    counter = get_latest_migration()[:4]
    new_counter = int(counter) + 1
    return str(new_counter).zfill(4)

def clean_obj_name(obj_name:str):
    names = obj_name.split(".")
    if not names[1].endswith("]"):
        i = names[1].index("]")
        return f"{names[0]}.{names[1][:i+1]}"
    return obj_name

def check_depend(sql:str, depend_objects:set):
    for o in depend_objects:
        if o.lower() in sql.lower():
            return True
    return False
        


class Command(BaseCommand):
    def handle(self, *args, **options):
        
        SQL_FILE_PATH = "HR/InitialSchema/schema.sql"
        DJANGO_MIGRATIONS_SAMPLE = "HR/InitialSchema/sample.py"
        MIGRATION_FILES_PATH = "HR/migrations"
        SQL_SCRIPTS_FILES_PATH = "HR/SQLScripts"


        self.stdout.write(self.style.NOTICE("Creating migration and sql script for object ..."))

        
        with open(SQL_FILE_PATH, "r", encoding="utf-16") as sql_file:
            x: str = sql_file.readlines()


        dependent_object = set()
        dependent_object.add(".dbo.")
        dependent_object.add(".[dbo].")

        for i, _ in enumerate(x):
            first_line_word = st_word(x[i], 0)
            if first_line_word == "create":
                object_type = st_word(x[i], 1).upper()
                object_name = clean_obj_name(st_word(x[i], 2))

                
                
                j = i
                create_query = []

                while True:
                    create_query.append(x[j])
                    
                    if st_word(x[j+1], 0) == "go":
                        context = {
                                "filename": f"{latest_counter(get_latest_migration())}_{object_type}_{object_name}",
                                "sql": "".join(create_query),
                                "reverse_sql":f"DROP {object_type} {object_name}",
                                "app_name": "HR",
                                "sql_path": f"{SQL_SCRIPTS_FILES_PATH}/{object_name}.sql",
                                "last_migration": f"{get_latest_migration()[:-3]}",
                                "datetime":datetime.now()
                            }

                        with open(DJANGO_MIGRATIONS_SAMPLE, "r", encoding="utf-8") as f:
                            template_file = f.read()
                        python_script = Template(template_file).render(Context(context))
                        
                        if check_depend(context['sql'], dependent_object):
                            dependent_object.add(object_name)
                            
                        
                        sql_path = f"{SQL_SCRIPTS_FILES_PATH}/{'[x]' if object_name.lower() in dependent_object else ''}{object_name}.sql"
                        with open(sql_path, "w", encoding="utf-8") as sql_file:
                            sql_file.write(context["sql"])
                        
                        if not object_type == "TABLE":
                            python_path = f"{MIGRATION_FILES_PATH}/{context['filename']}.py"
                            with open(python_path, "w", encoding="utf-8") as python_file:
                                python_file.write(python_script)

                        # dirty
                        if object_name.lower() in dependent_object:
                            self.stdout.write(self.style.WARNING(f"{object_type} {object_name}  DEPENDS ON ANOTHER DATABASE"))
                        else:
                            self.stdout.write(self.style.SUCCESS(f"{object_type} {object_name}  ..OK"))
                        break
                    
                    j+=1 
            
                
            