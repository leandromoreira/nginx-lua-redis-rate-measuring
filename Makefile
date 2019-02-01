build:
	docker-compose build nginx

up: down
	docker-compose up nginx

down:
	docker-compose down -v

build-test:
	docker-compose build test

test:
	docker-compose run --rm test

lint:
	docker-compose run --rm lint

.PHONY: build up down build-test test
