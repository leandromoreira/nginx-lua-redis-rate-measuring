build:
	docker-compose build

up:
	docker-compose up

down:
	docker-compose down -v

.PHONY: build up down
