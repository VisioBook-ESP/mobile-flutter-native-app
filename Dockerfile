# Stage 1: Flutter SDK
FROM ghcr.io/cirruslabs/flutter:3.38.7 AS builder

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy pubspec files first (cache layer)
COPY pubspec.yaml pubspec.lock ./

# Get dependencies
RUN flutter pub get

# Copy the rest of the source code
COPY . .

# Accept Android licenses
RUN yes | flutter doctor --android-licenses || true

# Default: build APK release
RUN flutter build apk --release

# Stage 2: Output artifacts
FROM scratch AS artifacts
COPY --from=builder /app/build/app/outputs/flutter-apk/app-release.apk /app-release.apk
