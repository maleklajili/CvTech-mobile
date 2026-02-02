# 📋 Tâches à Faire - CvTech Mobile

## 🔴 Priorité Haute (Bugs Critiques)

### 1. Correction des Images
- [x] Corriger `ImageUrlHelper` pour générer les URLs correctes
- [x] Utiliser `user.imageUrl` au lieu de `user.image` dans les widgets
- [x] Corriger le drawer_widget.dart pour utiliser `imageUrl`
- [ ] Tester l'affichage des images sur toutes les plateformes
- [ ] Ajouter un placeholder/fallback pour les images qui ne chargent pas

### 2. Configuration Réseau
- [x] Configurer `env.dart` avec détection automatique de plateforme
- [x] Activer `usesCleartextTraffic` dans AndroidManifest.xml
- [ ] Tester la connexion sur téléphone réel
- [ ] Ajouter un indicateur de connexion/déconnexion réseau

### 3. Authentification
- [x] Implémenter le refresh token automatique
- [ ] Gérer l'expiration de session proprement
- [ ] Ajouter biométrie (empreinte digitale)
- [ ] Sauvegarder les credentials pour "Se souvenir de moi"

---

## 🟠 Priorité Moyenne (Fonctionnalités)

### 4. Profil Utilisateur
- [ ] Implémenter la suppression d'image de profil
- [ ] Implémenter la suppression d'image de couverture
- [ ] Ajouter la preview avant upload
- [ ] Compresser les images avant envoi
- [ ] Ajouter crop/redimensionnement d'image

### 5. Éducation & Expérience
- [ ] Finaliser le formulaire d'éducation avec certificats
- [ ] Permettre l'ajout de plusieurs certificats par formation
- [ ] Ajouter la validation des dates (date fin > date début)
- [ ] Implémenter le tri par date

### 6. Compétences
- [ ] Afficher les compétences par catégorie
- [ ] Ajouter un slider pour le niveau de compétence
- [ ] Synchroniser avec le backend les catégories de compétences

### 7. Projets
- [ ] Permettre l'ajout d'images multiples
- [ ] Ajouter les liens (GitHub, démo)
- [ ] Afficher les technologies utilisées avec des badges

---

## 🟡 Priorité Basse (Améliorations)

### 8. UI/UX
- [ ] Ajouter animations de transition entre pages
- [ ] Implémenter skeleton loading
- [ ] Ajouter pull-to-refresh sur les listes
- [ ] Améliorer les messages d'erreur (plus descriptifs)
- [ ] Mode sombre complet

### 9. Performance
- [ ] Mettre en cache les données utilisateur
- [ ] Implémenter pagination pour les listes longues
- [ ] Optimiser le chargement des images (cache)
- [ ] Réduire les appels API redondants

### 10. Tests
- [ ] Écrire des tests unitaires pour les repositories
- [ ] Écrire des tests widget pour les formulaires
- [ ] Tests d'intégration pour le flux d'authentification
- [ ] Tests E2E sur émulateur

---

## 🔵 Nouvelles Fonctionnalités (Backlog)

### 11. Social
- [ ] Fil d'actualité (posts)
- [ ] Système de likes/commentaires
- [ ] Messagerie en temps réel
- [ ] Notifications push

### 12. Entreprises & Emplois
- [ ] Liste des entreprises
- [ ] Détail d'une entreprise
- [ ] Offres d'emploi
- [ ] Candidature en ligne

### 13. CV & Export
- [ ] Génération de CV PDF
- [ ] Choix de templates
- [ ] Partage du profil

---

## 📝 Notes Techniques

### Configuration pour téléphone réel
1. Trouver l'IP du PC : `ipconfig` (Windows) ou `ifconfig` (Mac/Linux)
2. Modifier `baseUrlRealDevice` dans `lib/core/env.dart`
3. S'assurer que le téléphone et le PC sont sur le même WiFi
4. Vérifier que le firewall Windows autorise le port 9000

### Commandes utiles
```bash
# Lancer sur Chrome
flutter run -d chrome

# Lancer sur Windows
flutter run -d windows

# Build APK
flutter build apk --release

# Analyser le code
flutter analyze

# Formater le code
dart format lib/
```

### Dépendances à ajouter
```yaml
# Pour les notifications
flutter_local_notifications: ^latest

# Pour le cache d'images
cached_network_image: ^latest

# Pour les animations
animations: ^latest

# Pour la biométrie
local_auth: ^latest
```

---

## ✅ Tâches Complétées

| Date | Tâche | Statut |
|------|-------|--------|
| 02/02/2026 | Correction erreurs null-safety profile_view.dart | ✅ |
| 02/02/2026 | Correction .env.local Next.js (URL invalide) | ✅ |
| 02/02/2026 | Correction test_image_upload_view.dart | ✅ |
| 02/02/2026 | Configuration next.config.ts pour images | ✅ |
| 02/02/2026 | Correction drawer_widget.dart (imageUrl) | ✅ |
| 02/02/2026 | Documentation architecture | ✅ |
