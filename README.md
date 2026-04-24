# VisioBook Mobile

Application mobile Flutter pour VisioBook — transformez vos textes en vidéos grâce à l'IA.

## Fonctionnalités

- **Import** : PDF, TXT, DOCX, EPUB ou scan de document (OCR)
- **Configuration** : style graphique, langue audio, durée
- **Génération IA** : suivi en temps réel avec étapes et progression
- **VisioBook Reader** : lecteur vertical type Webtoon avec scènes animées
- **Export** : téléchargement vidéo (480p/720p/1080p) + lien de partage
- **Abonnements** : plans Free/Premium/Enterprise via Stripe Payment Sheet
- **Profil** : gestion compte, quotas, thème clair/sombre, notifications

## Prérequis

- Flutter SDK >= 3.10.7
- Dart SDK
- Xcode (macOS/iOS) avec signing configuré
- Android Studio (Android)
- Docker (optionnel, pour build Android sans Flutter)

## Installation

```bash
make install
```

## Configuration

Créer un fichier `.env` à la racine (non versionné) :

```
STRIPE_PUBLISHABLE_KEY=pk_test_xxxxx
```

## Lancement

```bash
make run-macos    # macOS (charge automatiquement .env)
make run-ios      # iOS
make run-android  # Android
```

## Commandes utiles

```bash
make check     # Format + Analyze + Test
make format    # Formate le code Dart
make analyze   # Analyse statique (lint)
make test      # Lance les tests (~795 tests)
make ci        # Simulation CI complète
```

Voir `make help` pour la liste complète.

## Architecture

```
lib/
├── config/              # Configuration environnement (dev/prod), clé Stripe
├── core/
│   ├── network/         # Client HTTP (Dio) avec auth interceptor + token refresh
│   ├── routing/         # Navigation (GoRouter)
│   ├── services/        # NotificationService, SettingsProvider
│   ├── theme/           # Thème glassmorphism (clair/sombre) + Design System
│   ├── utils/           # Validators, Secure Storage
│   └── widgets/         # AppButton, AppInput, BottomNavBar, GradientBackground
└── features/
    ├── auth/            # Splash, onboarding, login, register, forgot/reset password
    ├── projects/        # Dashboard et liste des projets
    ├── project_detail/  # Configuration projet (style, langue, durée)
    ├── import/          # Import fichiers + scanner OCR
    ├── generation/      # Suivi génération avec SSE/polling
    ├── player/          # VisioBook Reader (scroll vertical, scènes)
    ├── export/          # Téléchargement vidéo + partage
    ├── history/         # Bibliothèque textes et VisioBooks
    ├── profile/         # Profil utilisateur, paramètres
    └── payment/         # Plans, abonnements Stripe, quotas
```

## API

Tous les services passent par un gateway unique :

| Environnement | URL |
|---------------|-----|
| Production | `https://visiobook.cloud/api/v1` |
| Dev | `http://51.178.52.51/api/v1` |

### Services connectés

| Service | Rôle | Statut |
|---------|------|--------|
| Core User Service | Auth, profils, sessions | En prod |
| Content Ingestion Service | Upload, OCR, extraction texte | En prod |
| Core Project Service | Projets, versions, workflows | En prod |
| Core Payment Service | Abonnements Stripe, quotas | En prod |
| AI Analysis Service | Analyse IA, génération scènes | En prod |
| AI Media Generation | Images, animations (ComfyUI) | En prod |

## Design System

L'app utilise un thème **glassmorphism** :
- Fonds semi-transparents avec bordures subtiles
- Dégradé pastel animé en arrière-plan
- Support complet mode clair et sombre
- Composants glass : boutons, cards, inputs, filtres, badges

## Tests

```bash
make test        # ~795 tests (unit + widget)
make test-cov    # Avec couverture
```

## Tester sur iPhone

1. Activer le **mode développeur** sur l'iPhone
2. Brancher en USB, accepter "Faire confiance"
3. Configurer le signing dans Xcode : `open ios/Runner.xcworkspace`
4. Lancer : `make run-ios`

## Tester sur Android

```bash
# Avec Flutter
flutter run -d android

# Sans Flutter (via Docker)
make docker-apk
# Puis installer l'APK sur le téléphone
```

## Docker

```bash
make docker-apk        # APK release
make docker-apk-debug  # APK debug
make docker-aab        # AAB Play Store
make docker-test       # Tests dans Docker
make docker-clean      # Nettoyage
```

## Stack technique

- **State Management** : Provider (ChangeNotifier)
- **Navigation** : GoRouter
- **HTTP** : Dio avec token refresh automatique (JWT RSA)
- **Stockage** : Flutter Secure Storage (Keychain/Encrypted SharedPrefs)
- **Paiement** : flutter_stripe (Payment Sheet natif)
- **Vidéo** : Chewie + video_player
- **Notifications** : flutter_local_notifications
- **Préférences** : SharedPreferences (thème, notifications)
- **Icons** : Lucide Icons
- **Scanner** : camera + edge_detection
