# TASKS - VisioBook Mobile App (POK)

> Base sur la documentation dans `/doc/`

---

## Progression globale

| Phase | Description | Priorite | Statut | Progression |
|-------|-------------|----------|--------|-------------|
| 0 | Setup Projet | P0 | Done | 100% |
| 1 | CI/CD | P0 | Done | 100% |
| 2 | Core / Infrastructure | P0 | Done | 100% |
| 3 | Authentification | P0 | Done | 95% |
| 4 | Dashboard | P0 | In Progress | 95% |
| 5 | Import Contenu | P0 | Done | 95% |
| 6 | Detail & Configuration | P0 | In Progress | 85% |
| 7 | Generation | P0 | Done | 85% |
| 8 | Player | P0 | Done | 85% |
| 9 | Export | P0 | Done | 80% |
| 10 | Historique | P1 | Done | 100% |
| 11 | Polish & QA | P2 | Done | 100% |
| 12 | Docker & Multi-platform Build | P1 | Done | 100% |
| 13 | Integration API - Donnees utilisateur | P0 | Todo | 0% |

---

## Note importante

> **AUTH CONNECTEE** : L'authentification est connectee au Core User Service (51.178.52.51:9999).
> `useMockData = false` dans `lib/config/environment.dart`. Les autres services ne sont pas encore disponibles.

---

## Priorites

| Niveau | Signification | POK |
|--------|---------------|-----|
| **P0** | Critique - MUST | Obligatoire |
| **P1** | Important - SHOULD | Recommande |
| **P2** | Moyen - COULD | Si le temps |
| **P3** | Bonus | Extra |

---

## Phase 0: Setup Projet [P0] ✅

- [x] Initialiser projet Flutter
- [x] Configurer Clean Architecture
- [x] Configurer .gitignore (doc/ exclu)
- [x] Creer repo GitHub (VisioBook-ESP/mobile-flutter-native-app)
- [x] Configurer branche dev par defaut

---

## Phase 1: CI/CD [P0] ✅

### Fichier CI
- [x] .github/workflows/ci.yml

### CI Pipeline (sur PR vers dev)
- [x] Job: format-check
- [x] Job: analyze-check
- [x] Job: test
- [x] Job: build-android (APK)
- [x] Job: build-ios

### A faire
- [x] Tester le pipeline CI complet (premier PR)

---

## Phase 2: Core / Infrastructure [P0] ✅

> Prerequis pour toutes les autres phases

- [x] Dependances pubspec.yaml
- [x] Configuration environnement (dev/prod)
- [x] Constantes API endpoints
- [x] Client HTTP avec intercepteurs
- [x] Theme et Design System
- [x] Validators (email, password)
- [x] Storage local secure (tokens)

---

## Phase 3: Authentification [P0]

> Ref: doc/04-mvp-screens.md - Ecrans 1 & 2
> API: Core User Service (port 9999)

### Splash Screen [P0]
- [x] Widget SplashScreen
- [x] Animation logo (fade + scale)
- [x] Verification token en background
- [x] Redirection (Dashboard/Onboarding/Login)

### Onboarding [P0]
- [x] Slide 1: "Importez votre texte"
- [x] Slide 2: "L'IA cree la magie"
- [x] Slide 3: "Regardez et partagez"
- [x] Navigation swipe + dots
- [x] Boutons Passer / Suivant / Commencer

### Login Screen [P0]
- [x] Champ email avec validation
- [x] Champ mot de passe avec toggle visibilite
- [x] Bouton "Se connecter"
- [x] Lien "Mot de passe oublie" (ecran + route)
- [x] Lien vers inscription
- [x] Gestion etats (loading, error, success)

### Register Screen [P0]
- [x] Champ nom d'utilisateur
- [x] Champ prenom + nom
- [x] Champ email avec validation
- [x] Champ mot de passe (8 chars, 1 maj, 1 chiffre)
- [ ] Checkbox CGU (commente, en attente des CGU)
- [x] Bouton "Creer mon compte"
- [ ] Ecran verification email (en attente API verify)

### API Endpoints [P0]
- [x] POST /api/v1/auth/register (connecte au cluster)
- [x] POST /api/v1/auth/login (connecte au cluster)
- [x] POST /api/v1/auth/refresh
- [ ] POST /api/v1/auth/verify

### OAuth [P3] (si Core User Service le supporte)
- [ ] Bouton "Continuer avec Google"
- [ ] Bouton "Continuer avec Apple"

---

## Phase 4: Dashboard [P0]

> Ref: doc/04-mvp-screens.md - Ecran 3
> API: Core Project Service (port 8086)

### Dashboard Screen [P0]
- [x] Header (logo "VisioBook", notifications bell)
- [x] Greeting "Bonjour, [Prenom] !"
- [x] StatsCard (X VisioBooks | Y Textes) en haut
- [x] Section "Mes VisioBooks" (scroll horizontal, tries par updatedAt)
- [x] Section "En cours" (brouillons + processing)
- [x] Empty state
- ~~Header menu burger~~ (supprime)
- ~~CTA "Nouveau VisioBook"~~ (supprime, le + suffit)
- ~~Section "Projets recents"~~ (supprime, fusionne avec Mes VisioBooks)

### Bottom Tab Bar [P0]
- [x] Tab Accueil (home) -> Dashboard
- [x] Tab Mes Textes (file-text) -> Bibliotheque textes
- [x] Bouton central Add (+) -> Modal import/scan
- [x] Tab Mes VisioBooks (play-circle) -> Bibliotheque VisioBooks
- [x] Tab Profil (user) -> Profil utilisateur
- ~~Tab Scanner (camera)~~ (supprime, remplace par Mes Textes)

### Composants [P0]
- [x] ProjectCard (thumbnail, titre, status, date)
- [x] StatsCard

### API Endpoints [P0]
- [x] GET /api/v1/projects
- [x] GET /api/v1/projects/recent

---

## Phase 5: Import Contenu [P0]

> Ref: doc/04-mvp-screens.md - Ecran 4
> API: Support Storage Service (port 8089)

### Input Mode Selection [P0]
- [x] Option "Scanner un document"
- [x] Option "Importer un fichier"

### Import de fichiers [P0] (US 1.1 - MUST)
- [x] File picker
- [x] Validation format (PDF, TXT, DOCX, EPUB)
- [x] Validation taille (max 50MB)
- [x] Progress bar upload
- [x] Gestion erreurs

### Scan de texte [P1] (US 1.2 - SHOULD)
- [x] Permission camera
- [x] UI cadrage page
- [x] Detection automatique bords
- [x] Capture image
- [x] Preview capture
- [x] Support multi-page
- [x] Toggle flash

### OCR Processing [P1]
- [x] Affichage texte extrait
- [x] Compteur mots
- [x] Option edition manuelle
- [x] Bouton "Continuer"

### Previsualisation [P1] (US 1.3 - SHOULD)
- [x] Afficher preview du texte
- [x] Resume automatique

### API Endpoints [P0]
- [x] POST /api/v1/storage/upload
- [x] POST /api/v1/storage/transform

---

## Phase 6: Detail & Configuration [P0]

> Ref: doc/04-mvp-screens.md - Ecran 7
> API: Core Project Service (port 8086)

### Detail Projet Screen [P0]
- [ ] Preview image/video
- [x] Titre et date
- [x] Resume du texte
- [x] Section configuration
- [x] Bouton "Generer VisioBook"

### Style graphique [P0] (US 2.1 - MUST)
- [x] Selecteur style (Realiste, Cartoon, Manga, Aquarelle)
- [x] Preview du style

### Langue audio [P1] (US 2.2 - SHOULD)
- [x] Selecteur langue (FR, EN, ES, DE)

### Duree [P2] (US 2.3 - COULD)
- [x] Selecteur duree (Courte, Moyenne, Longue, Auto)

### Personnalisation personnages [P3] (US 2.4 - COULD)
- [ ] Modifier apparence personnages

### Ambiance sonore [P3] (US 2.5 - COULD)
- [ ] Choisir musique de fond

### API Endpoints [P0]
- [x] GET /api/v1/projects/{id}
- [x] PUT /api/v1/projects/{id}
- [x] POST /api/v1/projects

---

## Phase 7: Generation [P0]

> Ref: doc/04-mvp-screens.md - Ecran 7.2

### Generation [P0] (US 3.1 - MUST)
- [x] Lancer generation
- [x] Animation loading
- [x] Bouton "Annuler"

### Suivi progression [P1] (US 3.3 - SHOULD)
- [x] Progress bar globale
- [x] Etape 1: Analyse (0-20%)
- [x] Etape 2: Images (20-60%)
- [x] Etape 3: Audio (60-80%)
- [x] Etape 4: Assemblage (80-100%)
- [x] Temps restant estime
- [ ] Bouton "Me notifier quand c'est pret"

### Preview scenes [P1] (US 3.4 - SHOULD)
- [ ] Thumbnails scenes intermediaires

### Gestion Erreurs [P0]
- [x] Ecran erreur
- [x] Options: Reessayer, Ajuster, Retour

### API Endpoints [P0]
- [x] POST /api/v1/projects/{id}/generate
- [x] GET /api/v1/projects/{id}/workflows/{workflowId}

---

## Phase 8: Player (VisioBook Reader) [P0]

> Ref: doc/04-mvp-screens.md - Ecran 8
> API: Support Storage Service (port 8089)
> Concept: Lecteur style Webtoon / BD animee - scroll vertical avec scenes

### VisioBook Reader [P0] (US 3.2 - MUST)
- [x] Scroll vertical type Webtoon (liste de scenes)
- [x] Affichage vignettes/images par scene
- [ ] Videos courtes par scene (auto-play au scroll)
- [ ] Audio par scene (declenchement a la visibilite)
- [x] Indicateur de progression (scene X/Y)

### Controles [P0] (US 3.5 - MUST)
- [x] Play / Pause global (audio + videos)
- [x] Sous-titres (toggle overlay)
- [x] Bouton mute/unmute
- [x] Barre de progression scenes (navigation rapide)

### Ecran de Fin [P0]
- [x] Ecran fin avec stats (temps lecture, nb scenes)
- [x] Bouton Rejouer (retour debut)
- [x] Bouton Partager
- [x] Bouton Retour au projet

### API Endpoints [P0]
- [x] GET /api/v1/projects/{id}/visiobook (scenes data)

---

## Phase 9: Export [P0]

> Ref: doc/04-mvp-screens.md - Ecran 8.3

### Download [P0] (US 4.1 - MUST)
- [x] Progress download
- [x] Sauvegarde device storage
- [x] Notification succes

### Format export [P1] (US 4.3 - SHOULD)
- [x] Choix qualite (480p, 720p, 1080p)
- [ ] Choix format (MP4)

### Lien partage [P1] (US 4.4 - SHOULD)
- [x] Generation lien unique
- [x] Copier presse-papier

### Partage reseaux sociaux [P2] (US 4.2 - COULD)
- [x] Share sheet natif

### API Endpoints [P0]
- [x] GET /api/v1/storage/download/{videoId}
- [x] POST /api/v1/projects/{id}/share

---

## Phase 10: Historique [P1]

> Ref: doc/04-mvp-screens.md - Ecrans 5 & 6

### Historique Inputs [P1] (US 5.1 - SHOULD)
- [x] Liste scrollable des textes
- [x] InputItem (icon type, titre, mots, date)
- [x] Filtres (Tous, Recents, Utilises)
- [x] Barre de recherche
- [x] Empty state

### Historique VisioBooks [P1] (US 5.1 - SHOULD)
- [x] Grille 2 colonnes
- [x] VisioBookCard (thumbnail, duree, titre, date, status)
- [x] Filtres
- [x] Empty state

### Supprimer projet [P1] (US 5.5 - SHOULD)
- [x] Swipe to delete
- [x] Confirmation suppression

### Modifier projet [P2] (US 5.2 - COULD)
- [x] Edition titre/texte

### Dupliquer projet [P2] (US 5.3 - COULD)
- [x] Creer copie du projet

### API Endpoints [P1]
- [x] GET /api/v1/projects
- [x] DELETE /api/v1/projects/{id}

---

## Phase 11: Polish & QA [P2] ✅

- [x] Animations transitions
- [x] Skeleton loaders
- [x] Pull to refresh
- [x] Empty states tous ecrans
- [x] Messages erreur user-friendly
- [x] Tests unitaires
- [x] Tests widgets

---

## Phase 12: Docker & Multi-platform Build [P1]

> Objectif: Permettre a tous les membres de l'equipe de build et tester l'app
> quel que soit leur environnement (Mac, PC, Linux)

### Dockerfile Flutter [P1]
- [x] Dockerfile avec Flutter SDK
- [x] Build Android APK/AAB dans le container
- [x] docker-compose.yml pour simplifier l'utilisation
- [x] Documentation d'utilisation (DOCKER.md)
- [x] .dockerignore pour optimiser les builds

### Build Android [P1]
- [x] Build APK debug (pour test rapide) - `make docker-apk-debug`
- [x] Build APK release (pour distribution) - `make docker-apk`
- [x] Build AAB (Android App Bundle pour Play Store) - `make docker-aab`
- [x] Script/Makefile pour lancer les builds facilement

### Build iOS [P1]
- [x] Documentation build iOS (necessite macOS + Xcode obligatoirement)
- [x] Script build iOS pour les devs sur Mac - `make build-ios-release`
- [x] Export IPA pour TestFlight - `make export-ipa`

### CI/CD Multi-platform [P1]
- [x] GitHub Action: build APK a chaque PR (existait deja)
- [x] GitHub Action: build iOS (existait deja, macos-latest)
- [x] Artifact upload (APK telechargeables depuis GitHub Actions, 30 jours)

### Targets de test [P1]
- [x] macOS (desktop Flutter) - `make run-macos`
- [x] Android emulateur (via APK) - `make docker-apk` + Android Studio
- [x] iPhone physique (via Xcode / TestFlight) - `make export-ipa`
- [x] Android physique (via APK sideload) - `make docker-apk`

---

## Phase 13: Integration API - Pret pour le live [P0]

> Objectif: S'assurer que TOUTES les donnees echangees avec les microservices sont correctement
> implementees pour fonctionner quand on passe `useMockData = false`.
>
> **Audit des problemes identifies :**
> - La config (style/langue/duree) n'est jamais envoyee au backend
> - Le `fileId` de l'import n'est pas lie au projet cote API
> - `createProject()` n'envoie que title/description, pas la config ni le fileId
> - `saveProject()` ne fait jamais de `PUT /projects/{id}` pour les projets existants
> - `generateProject()` fait un POST sans body (pas de config)
> - `uploadFile()` dans StorageService ne transmet pas la progression au callback `onProgress`
> - `uploadScannedImages()` n'envoie que la 1ere image, ignore les multi-pages
> - `Project.fromJson/toJson` ne gere pas `fileId`, `language`, `duration` (champs config)
> - Le download video utilise un endpoint invente (`/projects/{id}/video`) pas dans l'ApiClient
> - `ExportService.generateShareLink()` utilise `_apiClient.dio.post` au lieu de `_apiClient.shareProject()`

### 13.1 - Creer/Sauvegarder un projet avec toutes les donnees [P0]
- [ ] `createProject()` doit envoyer : title, description, fileId, config (style, language, duration)
- [ ] `ProjectService.createProject()` : ajouter params `fileId`, `config`
- [ ] `saveProject()` doit faire un `PUT /projects/{id}` pour les projets existants (actuellement no-op)
- [ ] `ProjectService` : ajouter methode `updateProject()` qui appelle `ApiClient.updateProject()`
- [ ] `Project.fromJson()` : parser les champs `fileId`, `language`, `duration`, `config`
- [ ] `Project.toJson()` : serialiser ces memes champs
- [ ] `Project` model : ajouter champ `fileId` pour stocker la reference au fichier uploade

### 13.2 - Lier le contenu importe au projet [P0]
- [ ] `initFromImport()` : stocker le `fileId` dans le provider (pas seulement dans l'id temporaire)
- [ ] Passer le `fileId` a `createProject()` lors de la sauvegarde
- [ ] `StorageService.uploadFile()` : brancher le callback `onProgress` sur Dio `onSendProgress`
- [ ] `uploadScannedImages()` : envoyer TOUTES les images (pas juste `imagePaths.first`)
- [ ] Apres upload multi-images : appeler `transformFile()` pour OCR et recuperer le texte

### 13.3 - Envoyer la config a la generation [P0]
- [ ] `ApiClient.generateProject()` : accepter un body `Map<String, dynamic>` optionnel
- [ ] `ProjectService.generateProject()` : accepter et passer un `ProjectConfig`
- [ ] `GenerationService.startGeneration()` : accepter et passer un `ProjectConfig`
- [ ] `ProjectDetailProvider.generateProject()` : passer `_config` au service
- [ ] `ProjectProvider.generateProject()` : accepter et passer un `ProjectConfig`

### 13.4 - Export & Partage [P0]
- [ ] `ExportService.downloadVideo()` : utiliser `ApiClient.getDownloadUrl()` puis download (pas un endpoint invente)
- [ ] `ExportService.generateShareLink()` : utiliser `_apiClient.shareProject()` au lieu de `_apiClient.dio.post()`
- [ ] Verifier que le `videoId` pour le download vient bien des donnees du projet/workflow

### 13.5 - Auth : champs manquants [P1]
- [ ] Login : stocker le `refresh_token` retourne (actuellement seul `access_token` est sauvegarde)
- [ ] Stocker et exposer `firstName`/`userName` depuis la reponse login (pas juste register)
- [ ] `AuthProvider.checkAuthStatus()` : recharger les infos user (nom, etc.) depuis le storage ou un `GET /users/me`

### 13.6 - VisioBook Reader : deserialisation [P0]
- [ ] Verifier que `VisiobookData.fromJson()` correspond au format reel de `GET /projects/{id}/visiobook`
- [ ] Gerer le cas ou le backend retourne un wrapper (ex: `{ "visiobook": { ... } }`)
- [ ] `VisiobookPanel.fromJson()` : gerer les types numeriques flexibles (int vs double pour `videoDurationMs`)

### 13.7 - Environment & Routing [P1]
- [ ] `EnvironmentConfig` : les URLs des services pointent toutes vers le meme path `/api/v1` — verifier si un API Gateway unifie ou si les ports doivent etre distincts
- [ ] Verifier que tous les endpoints utilisent le bon service URL (project vs storage vs user)

### 13.8 - Tests [P0]
- [ ] Tests unitaires : `ProjectConfig.toJson()` serialise correctement
- [ ] Tests unitaires : `Project.fromJson()` parse les nouveaux champs (fileId, config)
- [ ] Tests unitaires : `WorkflowState.fromJson()` gere tous les cas (types flexibles, champs null)
- [ ] Tests unitaires : `VisiobookData.fromJson()` avec le JSON de la spec
- [ ] Test d'integration : flux complet import -> config -> save -> generate avec les bons payloads

---

## Microservices Reference

| Service | Port | Role |
|---------|------|------|
| Core User Service | 9999 | Auth, profils, sessions |
| Core Project Service | 8086 | Projets, workflows |
| Support Storage Service | 8089 | Upload, stockage, streaming |
| AI Analysis Service | 8083 | Analyse IA, generation |
