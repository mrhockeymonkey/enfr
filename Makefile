FLUTTER_IMAGE := ghcr.io/cirruslabs/flutter:3.41.6
WORKDIR       := /build
PUB_CACHE_VOL := flutter-pub-cache

flutter-version:
	docker run --rm $(FLUTTER_IMAGE) flutter --version

build-web:
	docker run --rm \
		-v "$(PWD)/enfr:$(WORKDIR)" \
		-v "$(PUB_CACHE_VOL):/root/.pub-cache" \
		-w "$(WORKDIR)" \
		$(FLUTTER_IMAGE) \
		sh -c "flutter pub get && flutter build web --base-href /enfr/"

build-android:
	docker run --rm \
		-v "$(PWD)/enfr:$(WORKDIR)" \
		-v "$(PUB_CACHE_VOL):/root/.pub-cache" \
		-w "$(WORKDIR)" \
		$(FLUTTER_IMAGE) \
		sh -c "flutter pub get && flutter build apk --debug"

shell:
	docker run --rm -it \
		-v "$(PWD)/enfr:$(WORKDIR)" \
		-v "$(PUB_CACHE_VOL):/root/.pub-cache" \
		-w "$(WORKDIR)" \
		$(FLUTTER_IMAGE) \
		bash

.PHONY: flutter-version build-web build-android shell
