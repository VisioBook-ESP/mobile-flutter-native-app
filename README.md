# VisioBook Mobile

Application mobile Flutter pour VisioBook - transformez vos textes en videos grace a l'IA.

## Prerequis

- Flutter SDK >= 3.10.7
- Dart SDK
- Xcode (macOS/iOS) avec signing configure
- Android Studio (Android)

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
    ├── auth/        # Authentification (login, register, splash)
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

## Stack technique

- **State Management** : Provider
- **Navigation** : GoRouter
- **HTTP** : Dio avec token refresh automatique
- **Stockage** : Flutter Secure Storage (Keychain/Encrypted SharedPrefs)
- **Video** : Chewie + video_player
- **Icons** : Lucide Icons
