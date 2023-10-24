### SERVER
# --------
include .env.dev

docker.build: ## Build server in its docker container
	docker-compose up -d --build

docker.start.daemon: ## Start docker containers in daemon mode
	docker-compose up -d

docker.start: ## Start docker container
	docker compose start

docker.stop: ## Stop all containers
	docker compose stop

docker.django.migrate: ## Run all pending migrations
	docker-compose exec web python manage.py migrate --noinput

docker.django.makemigrations: ## Create a new migration
	docker-compose exec web python manage.py makemigrations

docker.django.showmigrations: ## Create a new migration
	docker-compose exec web python manage.py showmigrations

docker.django.collectstatic: ## Collect static files
	docker-compose exec web python manage.py collectstatic --no-input --clear

docker.prune: ## Well.. prune everything
	docker system prune -a
docker.restart: ## stop and start it again
	docker compose stop && docker compose start

database.connect: ## connect to the db
	docker-compose exec db psql --username=${SQL_USER} --dbname=${SQL_DATABASE}