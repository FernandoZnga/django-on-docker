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
	#docker compose stop
	docker stop $(docker ps -a -q)

docker.django.migrate: ## Run all pending migrations
	docker-compose exec web python manage.py migrate --noinput

docker.django.makemigrations: ## Create a new migration
	docker-compose exec web python manage.py makemigrations

docker.django.showmigrations: ## Create a new migration
	docker-compose exec web python manage.py showmigrations

docker.prune: ## Well.. prune everything
	#docker system prune --all --volumes --force
	docker system prune -a
docker.restart: ## Well.. prune everything
	docker compose stop && docker compose start
