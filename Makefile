# VisioBook Mobile - Makefile
# Commandes utiles pour le developpement Flutter

.PHONY: help install clean format analyze test build run \
	docker-apk docker-apk-debug docker-aab docker-test docker-clean \
	build-ios-release export-ipa

# Affiche l'aide
help:
	@echo "Commandes disponibles:"
	@echo "  make install     - Installe les dependances"
	@echo "  make clean       - Nettoie le projet"
	@echo "  make format      - Formate le code Dart"
	@echo "  make analyze     - Analyse le code (lint)"
	@echo "  make test        - Lance les tests"
	@echo "  make test-cov    - Lance les tests avec coverage"
	@echo "  make build-apk   - Build APK Android"
	@echo "  make build-ios   - Build iOS"
	@echo "  make run-android - Lance sur Android"
	@echo "  make run-ios     - Lance sur iOS"
	@echo "  make run-macos   - Lance sur macOS"
	@echo "  make run-web     - Lance sur Web"
	@echo "  make check       - Format + Analyze + Test"
	@echo "  make ci          - Simulation CI complete"

# Installe les dependances
install:
	flutter pub get

# Nettoie le projet
clean:
	flutter clean
	flutter pub get

# Formate le code
format:
	dart format .

# Analyse le code
analyze:
	flutter analyze

# Lance les tests
test:
	flutter test

# Lance les tests avec coverage
test-cov:
	flutter test --coverage

# Build APK Android (release)
build-apk:
	flutter build apk --release

# Build APK Android (debug)
build-apk-debug:
	flutter build apk --debug

# Build iOS
build-ios:
	flutter build ios --release --no-codesign

# Lance sur Android
run-android:
	flutter run -d android

# Lance sur iOS
run-ios:
	flutter run -d ios

# Lance sur macOS
run-macos:
	flutter run -d macos

# Lance sur Web
run-web:
	flutter run -d chrome

# Check complet (format + analyze + test)
check: format analyze test
	@echo "✓ Tous les checks sont passes!"

# Simulation CI complete
ci: clean format analyze test build-apk
	@echo "✓ CI simulation terminee avec succes!"

# Genere les icones de l'app (necessite flutter_launcher_icons)
icons:
	flutter pub run flutter_launcher_icons

# Genere le splash screen (necessite flutter_native_splash)
splash:
	flutter pub run flutter_native_splash:create

# Affiche les devices disponibles
devices:
	flutter devices

# Met a jour les dependances
upgrade:
	flutter pub upgrade

# Affiche les dependances obsoletes
outdated:
	flutter pub outdated

# Ouvre le projet dans Android Studio
open-android:
	open -a "Android Studio" android

# Ouvre le projet dans Xcode
open-ios:
	open ios/Runner.xcworkspace

# Git: commit avec format
commit: format analyze
	@echo "Code formate et analyse. Pret pour commit."

## --- Docker Build Targets ---

## Build APK release via Docker (any OS)
docker-apk:
	docker build --target artifacts --output build-output .
	@echo "APK disponible dans build-output/app-release.apk"

## Build APK debug via Docker
docker-apk-debug:
	docker compose run --rm build-apk-debug
	@echo "APK debug disponible dans build-output/"

## Build AAB via Docker (Play Store)
docker-aab:
	docker compose run --rm build-aab
	@echo "AAB disponible dans build-output/"

## Run tests via Docker
docker-test:
	docker compose run --rm test

## Clean Docker build artifacts
docker-clean:
	rm -rf build-output/
	docker compose down --rmi local --volumes 2>/dev/null || true

## --- iOS Build (macOS only) ---

## Build iOS (requires macOS + Xcode)
build-ios-release:
	flutter build ios --release --no-codesign
	@echo "Build iOS disponible dans build/ios/iphoneos/"

## Export IPA for TestFlight (requires signing)
export-ipa:
	flutter build ipa --release
	@echo "IPA disponible dans build/ios/ipa/"
