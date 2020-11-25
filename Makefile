.PHONY: docker-image

docker-image:
	if [ -d "db_data" ]; then sudo chown -R $(USER) db_data; fi
	if [ -d "rel/db_data" ]; then sudo chown -R $(USER) rel/db_data; fi
	docker build --ssh default . -t inn-checker --build-arg APP_NAME=inn_checker
	if [ -d "rel/db_data" ]; then sudo chown -R 70 rel/db_data; fi

upload:
	docker save -o /tmp/eco-rating.img eco-rating
	scp /tmp/eco-rating.img eco-rating.ru:/tmp
	rm /tmp/eco-rating.img
