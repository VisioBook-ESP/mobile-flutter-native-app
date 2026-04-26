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
| 13 | Integration API | P0 | Done | 100% |
| 14 | Profil Utilisateur | P1 | Done | 100% |
| 15 | Paiement & Abonnements | P1 | Done | 100% |
| 16 | UI Glassmorphism | P1 | Done | 100% |
=======
| 13 | Integration API - Donnees utilisateur | P0 | Done | 100% |
| 14 | Profil Utilisateur | P1 | Done | 100% |
>>>>>>> origin/dev

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
- [x] downloadVideo via videoUrl des versions du projet
- [x] generateShareLink via shareProject
- [x] videoUrl recupere depuis ProjectVersion (pas de videoId separe)
=======
- [x] `ExportService.downloadVideo()` : utiliser `ApiClient.getDownloadUrl()` puis download
- [x] `ExportService.generateShareLink()` : utiliser `_apiClient.shareProject()`
- [x] Verifier que le `videoId` pour le download vient bien des donnees du projet/workflow
>>>>>>> origin/dev

### 13.5 - Auth : champs manquants [P1] ✅
- [x] refresh_token, firstName/userName, checkAuthStatus

### 13.6 - VisioBook Reader : deserialisation [P0] ✅
<<<<<<< HEAD
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

### 13.9 - Documentation API [P1] ✅
- [x] Specs API recuperees et sauvegardees

---

## Phase 14: Profil Utilisateur [P1] ✅

<<<<<<< HEAD
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

- [x] Boutons primary : fond glass semi-transparent au lieu de noir opaque
- [x] Cards et containers : blanc 70% opacite au lieu d'opaque
- [x] Inputs : fond glass avec bordure subtile
- [x] Filtres (Tous/Recents, Tous/Prets/En cours) : glass au lieu de noir
- [x] Badges (Premium, Plan actuel) : glass avec bordure
- [x] Avatar initiales : glass au lieu de noir
- [x] Coherence mode clair / mode sombre

---

## Issues reportees a PI 4 (post-rendu)

| Issue | Titre | Raison |
|-------|-------|--------|
| #47 | Ancien mot de passe pour changement | Backend ne supporte pas old_password |
| #53 | Verification email post-inscription | Backend n'a pas /auth/verify |
| #46 | Flux mot de passe oublie | Backend n'a pas forgot/reset-password (issue core-user-service#58) |
| #49 | Notifications permissions | Depend du core-notification-service (PI 4.1) |
| #45 | Audio ambiance par page | Fonctionnalite player avancee |
| #54 | Ingestion polling backoff exponentiel | Optimisation non bloquante |
| #56 | Player pause au toucher | Bonus UX |
| #57 | Generation bouton annuler API | Bonus, bouton UI existe deja |
| #44 | Tests 80% couverture | PI 4.2, scanner non testable en unit |
| #69 | Tests UX beta testing | PI 4.3 |

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
