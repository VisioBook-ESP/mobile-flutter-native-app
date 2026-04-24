# Changelog

Toutes les modifications notables de ce projet sont documentées ici.

## [Unreleased] — PI 4 (post-rendu)

### Planifié
- Ancien mot de passe requis pour changement (#47)
- Vérification email post-inscription (#53)
- Flux mot de passe oublié connecté au backend (#46)
- Notifications push via core-notification-service (#49)
- Audio ambiance par page dans le player (#45)
- Backoff exponentiel pour le polling ingestion (#54)
- Pause au toucher dans le player (#56)
- Bouton annuler génération connecté à l'API (#57)
- Tests 80% de couverture (#44)
- Tests UX beta testing (#69)

---

## [1.0.0] — 2026-04-24 (PI 3.3)

### Ajouté

#### Paiement & Abonnements (#52)
- Intégration Stripe Payment Sheet native (iOS/Android)
- Écran de sélection de plans (Free/Premium/Enterprise) avec toggle mensuel/annuel
- Écran gestion d'abonnement (statut, usage, annulation)
- Modèles SubscriptionPlan avec PlanLimits, Quota avec format backend
- Vérification des quotas avant lancement d'une génération
- Configuration clé Stripe via `.env` et `--dart-define`
- Affichage quotas (générations + stockage) dans le profil

#### Profil Utilisateur (#40)
- Écran profil complet (infos personnelles, sécurité, compte)
- Modification inline (nom, prénom, username, email)
- Changement de mot de passe via bottom sheet
- Suppression de compte avec confirmation
- Section "Mon forfait" avec barres d'utilisation

#### Paramètres
- Toggle notifications (on/off) avec persistance SharedPreferences
- Sélecteur de thème Auto/Clair/Sombre avec persistance
- SettingsProvider branché sur le themeMode de l'app

#### Intégration API (#39)
- Export : videoUrl récupéré depuis les versions du projet (pas de videoId séparé)
- VisioBook Reader : désérialisation adaptée au format backend (scènes → panels)
- VisiobookPanel.fromScene() et VisiobookData.fromScenesResponse()
- Fallback automatique : /visiobook → /content/scenes
- Project.fromJson() : support statuts backend (active, completed, analyzing, failed)
- Support snake_case et format paginé {items: [...]}
- ApiClient : getVersions(), getVersion()

#### UI Glassmorphism (#72)
- Mode clair : fonds semi-transparents (blanc 70%) au lieu d'opaque
- Boutons, badges, filtres, cards, inputs en style glass
- Cohérence visuelle entre mode clair et sombre

### Modifié
- README.md mis à jour avec l'architecture complète
- Makefile : chargement automatique du `.env` pour les variables Stripe
- Environment : tous les services via gateway unique (visiobook.cloud)

---

## [0.9.0] — 2026-04-16

### Ajouté
- Retry mechanism pour les uploads de fichiers (#66)
- Flux mot de passe oublié/réinitialisation (UI prête, backend à venir) (#65)
- Lock sur le refresh token pour éviter les race conditions (#64)
- Suite de tests complète (65% couverture, ~780 tests) (#63)
- VisiobookData.fromJson robuste contre les variations backend (#62)
- Autoplay des vidéos dans le VisioBook reader (#61)
- Correction MIME type pour les images scannées (#60)

---

## [0.8.0] — 2026-04-10

### Ajouté
- SSE workflow tracking et ingestion polling en temps réel (#59)
- Notifications locales (génération terminée/échouée)
- Skeleton loaders sur tous les écrans
- Background generation avec suivi de progression
- Intégration paiement Stripe (UI + modèles) (#24)

---

## [0.7.0] — 2026-04-01

### Ajouté
- Refactor workflow avec endpoint unique `/projects/generate` (#25)
- Suppression folderId, simplification API (#23)
- Historique textes avec écran détail (#22)
- Profil aligné avec le core-user-service réel (#21)

---

## [0.6.0] — 2026-03-20

### Ajouté
- Phase 13 : intégration API complète (content-ingestion-service) (#19)
- Mock visiobook grid et refactor reader (#18)
- Phase 11 : polish (skeleton loaders, pull-to-refresh, 81 tests) (#17)
- Phase 10 : historique textes & VisioBooks avec recherche et filtres (#16)

---

## [0.5.0] — 2026-03-10

### Ajouté
- Phase 9 : export & partage (download vidéo, share link, share sheet) (#15)
- Phase 8 : VisioBook Reader (scroll vertical Webtoon, contrôles) (#14)
- Phase 7 : génération (progress bar, étapes, gestion erreurs)
- Phase 6 : configuration projet (style, langue, durée)

---

## [0.4.0] — 2026-02-20

### Ajouté
- Phase 5 : import contenu (file picker, scanner OCR, multi-page)
- Phase 4 : dashboard (projets, stats, bottom tab bar)
- Phase 3 : authentification (splash, onboarding, login, register)

---

## [0.3.0] — 2026-02-01

### Ajouté
- Phase 2 : core infrastructure (Dio, GoRouter, thème, validators, secure storage)
- Phase 1 : CI/CD (GitHub Actions : format, analyze, test, build)

---

## [0.1.0] — 2026-01-15

### Ajouté
- Phase 0 : setup projet Flutter initial
- Clean architecture
- Configuration repo GitHub
