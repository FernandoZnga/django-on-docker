# Project Setup

If you want to jump ahead and just download the development version, you can go [here](https://github.com/FernandoZnga/django-on-docker/tree/development)

## Requirements
We assume you already have (as of October 2023):
- Django v4.2.6
- Docker Desktop v4.24.2
- Python v3.11.6

Run the following:
```bash
$ mkdir django-on-docker && cd django-on-docker
$ mkdir app && cd app
$ python3 -m venv env
$ source env/bin/activate
(env) $

(env) $ pip install Django==4.2.6
(env) $ django-admin startproject django_project .
(env) $ python manage.py migrate
(env) $ python manage.py runserver
```
Go to http://localhost:8000 and you'll see your Django project running.

Create a file `requirements.txt` in the 'app' directory and add:
```text
Django==4.2.6
```
Folder structure by this point:
```text
└── app
    ├── hello_django
    │   ├── __init__.py
    │   ├── asgi.py
    │   ├── settings.py
    │   ├── urls.py
    │   └── wsgi.py
    ├── manage.py
    └── requirements.txt
```
NOTE: If you find a `db.sqlite3` file, you can delete it now if you want, we are going to use Postgres, so... disregard.
## Docker
Let's create a `Dockerfile` in the 'app' folder with the following content:
```Dockerfile
# pull official base image
FROM python:3.11.6-slim-buster

# set work directory
WORKDIR /usr/src/app

# set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# install dependencies
RUN pip install --upgrade pip
COPY ./requirements.txt .
RUN pip install -r requirements.txt

# copy project
COPY . .
```
Now we need a `docker-compose.yml` file, same root folder `app`:
```text
version: '3.9'
services:
  web:
    build: ./app
    command: python manage.py runserver 0.0.0.0:8000
    volumes:
      - ./app/:/usr/src/app/
    ports:
      - 8000:8000
    env_file:
      - ./.env.dev
```
There are a couple of variables in the `settings.py` file that should be updated now.

```text
import os

SECRET_KEY = os.environ.get("SECRET_KEY")

DEBUG = bool(os.environ.get("DEBUG", default=0))
# 'DJANGO_ALLOWED_HOSTS' should be a single string of hosts with a space between each.
# For example: 'DJANGO_ALLOWED_HOSTS=localhost 127.0.0.1 [::1]'
ALLOWED_HOSTS = os.environ.get("DJANGO_ALLOWED_HOSTS").split(" ")
```
The "secrets" should be remains that way, SECRET, this variables should be included in the `.env.dev` file (root project folder).

Folder structure by this point:
```text
└── app
    ├── django_project
    │   ├── __init__.py
    │   ├── asgi.py
    │   ├── settings.py
    │   ├── urls.py
    │   └── wsgi.py
    ├── Dockerfile
    ├── manage.py
    └── requirements.txt
└── env.dev
└── docker-compose.yml
```
Let's build and run it:
```bash
(env) $ docker-compose build
(env) $ docker-compose up -d
```
Goto [localhost](http://localhost:8000)
## Postgres
Instead of using the `db.sqlite3`, db by default, we're going to add the Postgres service into the `docker-compose.yml` file:
```text
version: '3.9'
services:
  web:
    build: ./app
    command: python manage.py runserver 0.0.0.0:8000
    volumes:
      - ./app/:/usr/src/app/
    ports:
      - 8000:8000
    env_file:
      - ./.env.dev
    depends_on:
      - db
  db:
    image: postgres:15
    volumes:
      - postgres_data:/var/lib/postgresql/data/
    environment:
      - POSTGRES_USER=hello_django
      - POSTGRES_PASSWORD=hello_django
      - POSTGRES_DB=hello_django_dev
volumes:
  postgres_data:
```
Make sure to add this new variables/values into the `.env.dev` file and update the `settings.py` file.
```text
# env file
DEBUG=true
SECRET_KEY=DjangoSecretKeyUsingDockerSecrets
DJANGO_ALLOWED_HOSTS=localhost 127.0.0.1 [::1]
SQL_ENGINE=django.db.backends.postgresql
SQL_DATABASE=django_project
SQL_USER=django_user
SQL_PASSWORD=django_password
SQL_HOST=db
SQL_PORT=5432
```
```text
# setting.py
DATABASES = {
    "default": {
        "ENGINE": os.environ.get("SQL_ENGINE", "django.db.backends.sqlite3"),
        "NAME": os.environ.get("SQL_DATABASE", BASE_DIR / "db.sqlite3"),
        "USER": os.environ.get("SQL_USER", "user"),
        "PASSWORD": os.environ.get("SQL_PASSWORD", "password"),
        "HOST": os.environ.get("SQL_HOST", "localhost"),
        "PORT": os.environ.get("SQL_PORT", "5432"),
    }
}
```
Remember that `Psycopg2` is the one we need to db connection, let's add this into `requirements.txt`
```text
Django==4.2.6
psycopg2-binary==2.9.9
```
Now you can build it again
```bash
(env) $ docker-compose up -d --build
```
Goto [localhost](http://localhost:8000)
### Quick Troubleshooting
If you have an issue, something like `database do not exist`, then remove the volumes, re-build, run it back again and apply the migrations.
```bash
# remove volumes
(env) $ docker-compose down -v
(env) $ docker-compose up -d --build
(env) $ python manage.py migrate
```
Every time we set up the server and db, we need to check if Postgres is right to work it on, so add a file into the 'app' from with the name `entrypoint.sh` with the following content:
```shell
#!/bin/sh

if [ "$DATABASE" = "postgres" ]
then
    echo "Waiting for postgres..."
    while ! nc -z $SQL_HOST $SQL_PORT; do
      sleep 0.1
    done
    echo "PostgresSQL started"
fi
python manage.py flush --no-input
python manage.py migrate
exec "$@"
```
Then update the permission:
```bash
$ chmod +x app/entrypoint.sh
```
Don't forget to update the `Dockerfile`, add the `entrypoint.sh` file, so it run as the Docker entry point:
```Dockerfile
# pull official base image
FROM python:3.11.4-slim-buster

# set work directory
WORKDIR /usr/src/app

# set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# install system dependencies
RUN apt-get update && apt-get install -y netcat

# install dependencies
RUN pip install --upgrade pip
COPY ./requirements.txt .
RUN pip install -r requirements.txt

# copy entrypoint.sh
COPY ./entrypoint.sh .
RUN sed -i 's/\r$//g' /usr/src/app/entrypoint.sh
RUN chmod +x /usr/src/app/entrypoint.sh

# copy project

COPY . .
# run entrypoint.sh

ENTRYPOINT ["/usr/src/app/entrypoint.sh"]
```
It's time to add the `DATABASE` environment variable into the `.env.dev` file.
```text
DEBUG=true
SECRET_KEY=PleaseUseAStrongSecretKeyHere
DJANGO_ALLOWED_HOSTS=localhost 127.0.0.1 [::1]
SQL_ENGINE=django.db.backends.postgresql
SQL_DATABASE=database_name_here
SQL_USER=database_user_here
SQL_PASSWORD=database_password_here
SQL_HOST=db
SQL_PORT=5432
DATABASE=postgres
```
By this point your project folder should look like:
```text
└── app
    ├── django_project
    │   ├── __init__.py
    │   ├── asgi.py
    │   ├── settings.py
    │   ├── urls.py
    │   └── wsgi.py
    ├── Dockerfile
    ├── entrypoint.sh
    ├── manage.py
    └── requirements.txt
└── env.dev
└── docker-compose.yml
```
If you remember, we leave the database credentials in the `docker.compose.yml` file
```text
    environment:
      - POSTGRES_USER=django_user
      - POSTGRES_PASSWORD=django_password
      - POSTGRES_DB=django_project
```
Instead of leaving it, at clear sight, let's create a new file `.env.dev.db` and type:
```text
POSTGRES_USER=django_user
POSTGRES_PASSWORD=django_password
POSTGRES_DB=django_project
```
Back in the `docker-compose.yml`, update the content with the following:
```text
version: '3.9'
services:
  web:
    build: ./app
    command: python manage.py runserver 0.0.0.0:8000
    volumes:
      - ./app/:/usr/src/app/
    ports:
      - "8000:8000"
    env_file:
      - ./.env.dev
    depends_on:
      - db
  db:
    image: postgres:15
    volumes:
      - postgres_data:/var/lib/postgresql/data/
    env_file:
      - ./.env.dev.db
volumes:
  postgres_data:
```
Notice that we remove the `environment` values and add the `env_file` section. Remember to add the `.env.dev.db` file as part if the `.gitignore`.
Run `make project.build` and you are done here.

Happy Coding!
