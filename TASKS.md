# TASKS - VisioBook Mobile App

> Base sur la documentation dans `/doc/`
> Derniere mise a jour : 2026-04-24

---

## Progression globale

| Phase | Description | Priorite | Statut | Progression |
|-------|-------------|----------|--------|-------------|
| 0 | Setup Projet | P0 | Done | 100% |
| 1 | CI/CD | P0 | Done | 100% |
| 2 | Core / Infrastructure | P0 | Done | 100% |
| 3 | Authentification | P0 | Done | 95% |
| 4 | Dashboard | P0 | Done | 100% |
| 5 | Import Contenu | P0 | Done | 100% |
| 6 | Detail & Configuration | P0 | Done | 95% |
| 7 | Generation | P0 | Done | 85% |
| 8 | Player | P0 | Done | 85% |
| 9 | Export | P0 | Done | 80% |
| 10 | Historique | P1 | Done | 100% |
| 11 | Polish & QA | P2 | Done | 100% |
| 12 | Docker & Multi-platform Build | P1 | Done | 100% |
<<<<<<< HEAD
<<<<<<< HEAD
| 13 | Integration API | P0 | Done | 100% |
| 14 | Profil Utilisateur | P1 | Done | 100% |
| 15 | Paiement & Abonnements | P1 | Done | 100% |
| 16 | UI Glassmorphism | P1 | Done | 100% |
=======
| 13 | Integration API - Donnees utilisateur | P0 | Done | 100% |
| 14 | Profil Utilisateur | P1 | Done | 100% |
>>>>>>> origin/dev
=======
| 13 | Integration API - Donnees utilisateur | P0 | Done | 100% |
| 14 | Profil Utilisateur | P1 | Done | 100% |
>>>>>>> 64275e1d8f243ab471440293033b83600e1eac98

---

## Note importante

> **Services connectes** :
> - Auth : Core User Service (visiobook.cloud) — login, register, refresh
> - Import : Content Ingestion Service — upload, extraction texte, ingestion
> - Paiement : Core Payment Service — plans, quotas, Stripe Payment Sheet
> - `useMockData = false` dans `lib/config/environment.dart`
> - Tous les services passent par le gateway unique : `https://visiobook.cloud/api/v1`

---

## Phases 0-12 : Terminées

Voir l'historique git pour le detail. Toutes les phases 0 a 12 sont 100% terminées.

---

## Phase 13: Integration API - Pret pour le live [P0] ✅

> Objectif: S'assurer que TOUTES les donnees echangees avec les microservices sont correctement
> implementees pour fonctionner quand on passe `useMockData = false`.

### 13.1 - Creer/Sauvegarder un projet avec toutes les donnees [P0] ✅
- [x] `createProject()` avec title, description, fileId, config
- [x] `updateProject()` via PUT /projects/{id}
- [x] `Project.fromJson/toJson` avec tous les champs

### 13.2 - Lier le contenu importe au projet [P0] ✅
- [x] fileId stocke et passe a createProject
- [x] uploadFile avec onProgress
- [x] Integration content-ingestion-service

### 13.3 - Envoyer la config a la generation [P0] ✅
- [x] Body optionnel sur generateProject, passage ProjectConfig

### 13.4 - Export & Partage [P0] ✅
<<<<<<< HEAD
<<<<<<< HEAD
- [x] downloadVideo via videoUrl des versions du projet
- [x] generateShareLink via shareProject
- [x] videoUrl recupere depuis ProjectVersion (pas de videoId separe)
=======
- [x] `ExportService.downloadVideo()` : utiliser `ApiClient.getDownloadUrl()` puis download
- [x] `ExportService.generateShareLink()` : utiliser `_apiClient.shareProject()`
- [x] Verifier que le `videoId` pour le download vient bien des donnees du projet/workflow
>>>>>>> origin/dev
=======
- [x] downloadVideo via videoUrl des versions du projet
- [x] generateShareLink via shareProject
- [x] videoUrl recupere depuis ProjectVersion (pas de videoId separe)
>>>>>>> 64275e1d8f243ab471440293033b83600e1eac98

### 13.5 - Auth : champs manquants [P1] ✅
- [x] refresh_token, firstName/userName, checkAuthStatus

### 13.6 - VisioBook Reader : deserialisation [P0] ✅
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> 64275e1d8f243ab471440293033b83600e1eac98
- [x] VisiobookData.fromJson() + fromScenesResponse() pour format backend
- [x] Wrapper {"data": {...}} gere
- [x] VisiobookPanel.fromScene() pour convertir les scenes backend en panels
- [x] Types numeriques flexibles

### 13.7 - Environment & Routing [P1] ✅
- [x] ingestionServiceUrl dans EnvironmentConfig
- [x] URLs verifiees (gateway unique, pas de ports exposes)

### 13.8 - Tests [P0] ✅
- [x] Tests unitaires pour les nouveaux champs
- [x] Tests fromScene, fromScenesResponse
- [x] Tests endpoints API (getVersions, getVersion)
<<<<<<< HEAD
=======
- [x] Verifier que `VisiobookData.fromJson()` correspond au format reel
- [x] Gerer le cas ou le backend retourne un wrapper
- [x] `VisiobookPanel.fromJson()` : gerer les types numeriques flexibles

### 13.7 - Environment & Routing [P1] ✅
- [x] Ajouter `ingestionServiceUrl` dans `EnvironmentConfig`
- [x] Verifier les URLs/ports quand les services seront deployes

### 13.8 - Tests [P0] ✅
- [x] Tests unitaires pour les nouveaux champs
- [x] Test d'integration du flux complet
>>>>>>> origin/dev
=======
>>>>>>> 64275e1d8f243ab471440293033b83600e1eac98

### 13.9 - Documentation API [P1] ✅
- [x] Specs API recuperees et sauvegardees

---

## Phase 14: Profil Utilisateur [P1] ✅

<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> 64275e1d8f243ab471440293033b83600e1eac98
> Ref: Core User Service

### Ecran Profil ✅
- [x] Header profil (initiales, nom, email)
- [x] Modifier nom / prenom / username (inline-editable)
- [x] Modifier email (inline-editable avec hint verification)
- [x] Modifier mot de passe (bottom sheet)
- ~~Upload / modifier avatar~~ (supprime)

### Section Quotas ✅
- [x] Affichage generations utilisees / limite
- [x] Affichage stockage utilise / limite (Go)
- [x] Jauge visuelle

### Parametres ✅
- [x] Notifications toggle (on/off) — SettingsProvider + SharedPreferences
- [x] Theme clair/sombre — selecteur Auto/Clair/Sombre avec persistance
- ~~Langue de l'app (FR/EN)~~ (supprime, on reste en francais)

### Compte ✅
<<<<<<< HEAD
=======
> Ref: Core User Service (port 9999)
> Paiement/abonnements : voir issue #52

### Ecran Profil [P1] ✅
- [x] Header profil (avatar, nom, email)
- [x] Section "Informations personnelles"
- [x] Modifier nom / prenom / username
- [x] Modifier email (inline-editable avec hint verification)
- [x] Modifier mot de passe (ancien + nouveau)
- ~~Upload / modifier avatar~~ (supprime)

### Section Credits & Tokens [P1] ✅
- [x] Affichage solde credits/tokens
- [x] Jauge visuelle (credits restants / total)
- ~~Historique d'utilisation des credits~~ (deplace vers #52, ce sont des quotas d'abonnement)

### Section Paiement [P1]
- [x] UI "Mes moyens de paiement" (liste vide + placeholder)
- ~~UI "Ajouter un moyen de paiement"~~ (deplace vers #52)
- ~~UI "Acheter des credits"~~ (deplace vers #52, ce sont des plans d'abonnement)

### Parametres [P2] ✅
- ~~Langue de l'app (FR/EN)~~ (supprime, on reste en francais)
- [x] Notifications (toggle on/off) - SettingsProvider + SharedPreferences
- [x] Theme (clair/sombre) - selecteur Auto/Clair/Sombre avec persistance

### Compte [P1]
>>>>>>> origin/dev
=======
>>>>>>> 64275e1d8f243ab471440293033b83600e1eac98
- [x] Bouton "Se deconnecter"
- [x] Bouton "Supprimer mon compte" (avec confirmation)
- [x] Mentions legales / CGU
- [x] Version de l'app

### API Endpoints ✅
- [x] GET /api/v1/users/me
- [x] PUT /api/v1/users/me
- [x] DELETE /api/v1/users/me

---

## Phase 15: Paiement & Abonnements [P1] ✅

> Ref: Core Payment Service (Stripe)

### Models ✅
- [x] SubscriptionPlan avec PlanLimits (generationsPerMonth, storageGB, exportQuality, watermark)
- [x] Quota avec format backend (generations.used/limit, storage en bytes converti en Go)
- [x] Subscription (id, planId, status, periode)
- [x] Plans : Free (0€), Premium (9.99€/mois), Enterprise (29.99€/mois)

### Ecran Plans ✅
- [x] Toggle mensuel/annuel
- [x] Cards plan avec features, prix, badge "Recommande"
- [x] Bouton upgrade → Stripe Payment Sheet (mobile) ou message desktop
- [x] Bouton downgrade avec confirmation

### Ecran Abonnement ✅
- [x] Plan actuel avec statut (actif/annule)
- [x] Barres d'utilisation generations + stockage
- [x] Bouton annuler avec raison optionnelle

### Integration Stripe ✅
- [x] flutter_stripe configure via .env (STRIPE_PUBLISHABLE_KEY)
- [x] POST /payment-intent → initPaymentSheet → presentPaymentSheet
- [x] Rechargement quotas apres paiement
- [x] MissingPluginException catch pour desktop

### Quota check ✅
- [x] Verification quotas avant lancement generation

### API Endpoints ✅
- [x] GET /api/v1/subscriptions/plans
- [x] GET /api/v1/subscriptions/current
- [x] GET /api/v1/quotas
- [x] POST /api/v1/subscriptions/payment-intent
- [x] POST /api/v1/subscriptions/cancel
- [x] POST /api/v1/subscriptions/upgrade
- [x] POST /api/v1/subscriptions/downgrade

---

## Phase 16: UI Glassmorphism [P1] ✅

### 13.2 - Lier le contenu importe au projet [P0] ✅
- [x] `initFromImport()` : stocker le `fileId` dans le provider (pas seulement dans l'id temporaire)
- [x] Passer le `fileId` a `createProject()` lors de la sauvegarde
- [x] `StorageService.uploadFile()` : brancher le callback `onProgress` sur Dio `onSendProgress`
- [x] `uploadScannedImages()` : envoyer TOUTES les images (pas juste `imagePaths.first`)
- [x] Integrer le content-ingestion-service (upload + extract text en 2 etapes)

### 13.3 - Envoyer la config a la generation [P0] ✅
- [x] `ApiClient.generateProject()` : accepter un body `Map<String, dynamic>` optionnel
- [x] `ProjectService.generateProject()` : accepter et passer un `ProjectConfig`
- [x] `GenerationService.startGeneration()` : accepter et passer un `ProjectConfig`
- [x] `ProjectDetailProvider.generateProject()` : passer `_config` au service
- [x] `ProjectProvider.generateProject()` : accepter et passer un `ProjectConfig`

### 13.4 - Export & Partage [P0] ✅
- [x] `ExportService.downloadVideo()` : utiliser `ApiClient.getDownloadUrl()` puis download
- [x] `ExportService.generateShareLink()` : utiliser `_apiClient.shareProject()`
- [x] Verifier que le `videoId` pour le download vient bien des donnees du projet/workflow

### 13.5 - Auth : champs manquants [P1] ✅
- [x] Login : stocker le `refresh_token` retourne
- [x] Stocker et exposer `firstName`/`userName` depuis la reponse login
- [x] `AuthProvider.checkAuthStatus()` : recharger le nom user depuis le storage

### 13.6 - VisioBook Reader : deserialisation [P0] ✅
- [x] Verifier que `VisiobookData.fromJson()` correspond au format reel
- [x] Gerer le cas ou le backend retourne un wrapper
- [x] `VisiobookPanel.fromJson()` : gerer les types numeriques flexibles

### 13.7 - Environment & Routing [P1] ✅
- [x] Ajouter `ingestionServiceUrl` dans `EnvironmentConfig`
- [x] Verifier les URLs/ports quand les services seront deployes

### 13.8 - Tests [P0] ✅
- [x] Tests unitaires pour les nouveaux champs
- [x] Test d'integration du flux complet

### 13.9 - Documentation API [P1] ✅
- [x] Recuperer les specs API depuis docs-architecture
- [x] Sauvegarder dans `docs/api/`

---

## Phase 14: Profil Utilisateur [P1]

> Ref: Core User Service (port 9999)
> Paiement/abonnements : voir issue #52

### Ecran Profil [P1] ✅
- [x] Header profil (avatar, nom, email)
- [x] Section "Informations personnelles"
- [x] Modifier nom / prenom / username
- [x] Modifier email (inline-editable avec hint verification)
- [x] Modifier mot de passe (ancien + nouveau)
- ~~Upload / modifier avatar~~ (supprime)

### Section Credits & Tokens [P1] ✅
- [x] Affichage solde credits/tokens
- [x] Jauge visuelle (credits restants / total)
- ~~Historique d'utilisation des credits~~ (deplace vers #52, ce sont des quotas d'abonnement)

### Section Paiement [P1]
- [x] UI "Mes moyens de paiement" (liste vide + placeholder)
- ~~UI "Ajouter un moyen de paiement"~~ (deplace vers #52)
- ~~UI "Acheter des credits"~~ (deplace vers #52, ce sont des plans d'abonnement)

### Parametres [P2] ✅
- ~~Langue de l'app (FR/EN)~~ (supprime, on reste en francais)
- [x] Notifications (toggle on/off) - SettingsProvider + SharedPreferences
- [x] Theme (clair/sombre) - selecteur Auto/Clair/Sombre avec persistance

### Compte [P1]
- [x] Bouton "Se deconnecter"
- [x] Bouton "Supprimer mon compte" (avec confirmation)
- [x] Mentions legales / CGU
- [x] Version de l'app

### Navigation [P1]
- [x] Route /profile
- [x] Acces depuis le tab Profil de la bottom nav bar (remplacer le modal actuel)

### API Endpoints [P1]
- [x] GET /api/v1/users/me
- [x] PUT /api/v1/users/me
- [x] PUT /api/v1/users/me/password
- [x] DELETE /api/v1/users/me
- [x] GET /api/v1/users/me/credits (quand disponible)

---

## Microservices Reference

| Service | Role | Statut |
|---------|------|--------|
| Core User Service | Auth, profils, sessions | En prod |
| Content Ingestion Service | Upload, OCR, extraction texte | En prod |
| Core Project Service | Projets, versions, workflows, scenes | En prod |
| Core Payment Service | Abonnements Stripe, quotas | En prod |
| AI Analysis Service | Analyse IA, generation scenes | En prod |
| AI Media Generation Service | Images, animations (ComfyUI) | En prod |
| AI Storyboard Assembly | Assemblage video final | En cours |
| Core Notification Service | Email, push notifications | PI 4.1 |

> Tous les services passent par le gateway API : `https://visiobook.cloud/api/v1`
