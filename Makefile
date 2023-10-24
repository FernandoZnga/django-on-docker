include makefiles/server.mk

PYTHON = python3

.DEFAULT_GOAL = help

project.build: docker.build ## Build the server on Docker container

containers.start: docker.start ## Build the server on Docker container

containers.start.daemon: docker.start.daemon ## Build the server on Docker container

containers.restart: docker.restart ## Stop and Start everything again

containers.stop: docker.stop ## Stop all docker containers

containers.prune: docker.prune ## Stop all docker containers

migrations.run: docker.server.migrate ## run the migrations

migrations.create: docker.django.makemigrations ## create the most recent migrations

migrations.show: docker.django.showmigrations

help:
	@echo "------------------------------HELP MENU----------------------------------"
	@echo "	To build the project type        'make project.build'"
	@echo "	To start the containers type     'make containers.start'"
	@echo "	To start in daemon mode type     'make containers.start.daemon'"
	@echo "	To restart the containers type   'make containers.restart'"
	@echo "	To stop all containers type      'make containers.stop'"
	@echo "	To prune/delete everything type  'make migrations.run'"
	@echo "	To create the migrations type    'make migrations.create'"
	@echo "	To apply the migrations type     'make migrations.run'"
	@echo "	To view the migrations type      'make migrations.show'"
	@echo "-------------------------------------------------------------------------"
