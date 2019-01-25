build:
	docker-compose build

up: down
	docker-compose up

down:
	docker-compose down -v

build-test:
	docker-compose build test

test:
	docker-compose run --rm test

.PHONY: build up down build-test test
