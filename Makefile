build:
	docker-compose build

up: down
	docker-compose up

down:
	docker-compose down -v

.PHONY: build up down
