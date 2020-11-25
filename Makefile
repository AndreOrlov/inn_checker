.PHONY: docker-image

docker-image:
	if [ -d "db_data" ]; then sudo chown -R $(USER) db_data; fi
	if [ -d "rel/db_data" ]; then sudo chown -R $(USER) rel/db_data; fi
	docker build . -t inn-checker --build-arg APP_NAME=inn_checker

upload:
	docker save -o /tmp/inn-checker.img inn-checker
	scp /tmp/inn-checker.img andre@84.201.164.251:/tmp
	rm /tmp/inn-checker.img
