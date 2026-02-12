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
| 5 | Import Contenu | P0 | In Progress | 60% |
| 6 | Detail & Configuration | P0 | In Progress | 80% |
| 7 | Generation | P0 | Todo | 0% |
| 8 | Player | P0 | Todo | 0% |
| 9 | Export | P0 | Todo | 0% |
| 10 | Historique | P1 | Todo | 0% |
| 11 | Polish & QA | P2 | Todo | 0% |

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
- [ ] Permission camera
- [ ] UI cadrage page
- [ ] Detection automatique bords
- [ ] Capture image
- [ ] Preview capture
- [ ] Support multi-page
- [ ] Toggle flash

### OCR Processing [P1]
- [x] Affichage texte extrait
- [x] Compteur mots
- [ ] Option edition manuelle
- [x] Bouton "Continuer"

### Previsualisation [P1] (US 1.3 - SHOULD)
- [x] Afficher preview du texte
- [ ] Resume automatique

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
- [ ] Lancer generation
- [ ] Animation loading
- [ ] Bouton "Annuler"

### Suivi progression [P1] (US 3.3 - SHOULD)
- [ ] Progress bar globale
- [ ] Etape 1: Analyse (0-20%)
- [ ] Etape 2: Images (20-60%)
- [ ] Etape 3: Audio (60-80%)
- [ ] Etape 4: Assemblage (80-100%)
- [ ] Temps restant estime
- [ ] Bouton "Me notifier quand c'est pret"

### Preview scenes [P1] (US 3.4 - SHOULD)
- [ ] Thumbnails scenes intermediaires

### Gestion Erreurs [P0]
- [ ] Ecran erreur
- [ ] Options: Reessayer, Ajuster, Retour

### API Endpoints [P0]
- [ ] POST /api/v1/projects/{id}/generate
- [ ] GET /api/v1/projects/{id}/workflows/{workflowId}

---

## Phase 8: Player [P0]

> Ref: doc/04-mvp-screens.md - Ecran 8
> API: Support Storage Service (port 8089)

### Video Player [P0] (US 3.2 - MUST)
- [ ] Video player
- [ ] Chargement et buffering

### Controles [P0] (US 3.5 - MUST)
- [ ] Play / Pause
- [ ] Timeline draggable
- [ ] Temps actuel / duree totale
- [ ] Rewind (-10s)
- [ ] Forward (+10s)
- [ ] Fullscreen
- [ ] Sous-titres (toggle)
- [ ] Vitesse (0.5x, 1x, 1.5x, 2x)

### Ecran de Fin [P0]
- [ ] Bouton Rejouer
- [ ] Bouton Partager
- [ ] Bouton Telecharger
- [ ] Retour au projet

### API Endpoints [P0]
- [ ] GET /api/v1/storage/stream/{videoId}

---

## Phase 9: Export [P0]

> Ref: doc/04-mvp-screens.md - Ecran 8.3

### Download [P0] (US 4.1 - MUST)
- [ ] Progress download
- [ ] Sauvegarde device storage
- [ ] Notification succes

### Format export [P1] (US 4.3 - SHOULD)
- [ ] Choix qualite (480p, 720p, 1080p)
- [ ] Choix format (MP4)

### Lien partage [P1] (US 4.4 - SHOULD)
- [ ] Generation lien unique
- [ ] Copier presse-papier

### Partage reseaux sociaux [P2] (US 4.2 - COULD)
- [ ] Share sheet natif

### API Endpoints [P0]
- [ ] GET /api/v1/storage/download/{videoId}
- [ ] POST /api/v1/projects/{id}/share

---

## Phase 10: Historique [P1]

> Ref: doc/04-mvp-screens.md - Ecrans 5 & 6

### Historique Inputs [P1] (US 5.1 - SHOULD)
- [ ] Liste scrollable des textes
- [ ] InputItem (icon type, titre, mots, date)
- [ ] Filtres (Tous, Recents, Utilises)
- [ ] Barre de recherche
- [ ] Empty state

### Historique VisioBooks [P1] (US 5.1 - SHOULD)
- [ ] Grille 2 colonnes
- [ ] VisioBookCard (thumbnail, duree, titre, date, status)
- [ ] Filtres
- [ ] Empty state

### Supprimer projet [P1] (US 5.5 - SHOULD)
- [ ] Swipe to delete
- [ ] Confirmation suppression

### Modifier projet [P2] (US 5.2 - COULD)
- [ ] Edition titre/texte

### Dupliquer projet [P2] (US 5.3 - COULD)
- [ ] Creer copie du projet

### API Endpoints [P1]
- [ ] GET /api/v1/projects
- [ ] DELETE /api/v1/projects/{id}

---

## Phase 11: Polish & QA [P2]

- [ ] Animations transitions
- [ ] Skeleton loaders
- [ ] Pull to refresh
- [ ] Empty states tous ecrans
- [ ] Messages erreur user-friendly
- [ ] Tests unitaires
- [ ] Tests widgets

---

## Microservices Reference

| Service | Port | Role |
|---------|------|------|
| Core User Service | 9999 | Auth, profils, sessions |
| Core Project Service | 8086 | Projets, workflows |
| Support Storage Service | 8089 | Upload, stockage, streaming |
| AI Analysis Service | 8083 | Analyse IA, generation |
