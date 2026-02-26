# VisioBook Mobile

Application mobile Flutter pour VisioBook - transformez vos textes en videos grace a l'IA.

## Prerequis

- Flutter SDK >= 3.10.7
- Dart SDK
- Xcode (macOS/iOS) avec signing configure
- Android Studio (Android)
- Docker (optionnel, pour build Android sans Flutter)

## Installation

```bash
make install
```

## Lancement

```bash
make run-macos    # macOS
make run-ios      # iOS
make run-android  # Android
```

## Commandes utiles

```bash
make check     # Format + Analyze + Test
make format    # Formate le code Dart
make analyze   # Analyse statique (lint)
make test      # Lance les tests
make ci        # Simulation CI complete
```

Voir `make help` pour la liste complete.

## Architecture

```
lib/
├── config/          # Configuration environnement (dev/prod)
├── core/
│   ├── network/     # Client HTTP (Dio) avec intercepteurs
│   ├── routing/     # Navigation (GoRouter)
│   ├── theme/       # Theme et Design System
│   ├── utils/       # Validators, Secure Storage
│   └── widgets/     # Composants reutilisables (AppButton, AppInput, BottomNavBar)
└── features/
    ├── auth/        # Authentification (splash, onboarding, login, register, mot de passe oublie)
    ├── projects/    # Dashboard et liste des projets
    ├── project_detail/ # Configuration projet (style, langue, duree)
    ├── import/      # Import de fichiers (PDF, TXT, DOCX, EPUB)
    └── player/      # Lecteur video avec selecteur de generation
```

## Configuration API

Les URLs des microservices sont configurees dans `lib/config/environment.dart` :

| Service | Port | Role |
|---------|------|------|
| Core User Service | 9999 | Auth, profils |
| Core Project Service | 8086 | Projets, workflows |
| Support Storage Service | 8089 | Upload, stockage, streaming |
| AI Analysis Service | 8083 | Analyse IA, generation |

## Configuration macOS

Pour le developpement macOS, ouvrir Xcode une fois pour configurer la signature :

```bash
open macos/Runner.xcworkspace
```

Puis dans **Signing & Capabilities** : activer **Automatically manage signing** et selectionner votre Team.

## Docker - Build Android (sans Flutter)

Docker permet de build l'APK Android **sans installer Flutter ni Android SDK**.
Utile pour les devs sur PC Windows ou Linux qui veulent tester sur Android.

> **Note**: Le build iOS necessite obligatoirement macOS + Xcode. Docker ne peut pas contourner cette limitation Apple.

### Build Android via Docker

```bash
# Build APK release (recommande pour tester)
make docker-apk

# Build APK debug (plus rapide, pour dev)
make docker-apk-debug

# Build AAB pour le Play Store
make docker-aab
```

Les fichiers generes se trouvent dans le dossier `build-output/`.

### Tests via Docker

```bash
make docker-test
```

### Nettoyage Docker

```bash
make docker-clean
```

## Build iOS (macOS uniquement)

Le build iOS necessite macOS + Xcode. Prerequis : CocoaPods (`sudo gem install cocoapods`).

```bash
# Build iOS sans signature (pour test)
make build-ios-release

# Export IPA pour TestFlight (necessite un profil de signature)
make export-ipa
```

## Installer l'APK sur un telephone Android

### Via USB (sideload)
1. Activer le **mode developpeur** sur le telephone Android
2. Activer **Debogage USB** dans les parametres developpeur
3. Connecter le telephone en USB
4. Executer :
```bash
adb install build-output/app-release.apk
```

### Via transfert de fichier
1. Copier `build-output/app-release.apk` sur le telephone (email, drive, USB)
2. Ouvrir le fichier APK sur le telephone
3. Autoriser l'installation depuis des sources inconnues si demande

## Test sur differents environnements

| Plateforme | Methode | Prerequis |
|-----------|---------|-----------|
| Android physique | APK sideload | Docker (any OS) |
| Android emulateur | APK + Android Studio | Android Studio |
| macOS desktop | `make run-macos` | macOS + Flutter SDK |
| iPhone physique | TestFlight ou Xcode | macOS + Xcode |
| iPhone simulateur | `make run-ios` | macOS + Xcode |

## Troubleshooting

### Le build Docker est lent
Le premier build telecharge le SDK Flutter (~2GB). Les builds suivants utilisent le cache Docker.

### Erreur de memoire Docker
Le build Android necessite au moins 4GB de RAM. Augmentez la memoire dans Docker Desktop > Settings > Resources.

### Erreur Gradle
```bash
make docker-clean
make docker-apk
```

## Stack technique

- **State Management** : Provider
- **Navigation** : GoRouter
- **HTTP** : Dio avec token refresh automatique
- **Stockage** : Flutter Secure Storage (Keychain/Encrypted SharedPrefs)
- **Video** : Chewie + video_player
- **Icons** : Lucide Icons
