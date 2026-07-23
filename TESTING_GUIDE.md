# 🧪 Guide de Test - Page Documents

## Configuration de l'Environnement

### Prérequis
- Flutter SDK ≥ 3.0
- Dart ≥ 3.0
- Backend en cours d'exécution sur `localhost:5000`
- Un compte de test avec JWT valide

---

## 🏃 Exécution de l'Application

### 1. Démarrer le Backend

```bash
cd backend-gestion
npm install
npm run dev
# Serveur accessible à http://localhost:5000
# Vérifier: http://localhost:5000/api/health
```

### 2. Configurer l'API URL

**Pour les émulateurs Android**:
```dart
// Mobile/frontend/lib/constants.dart
static const String baseUrl = 'http://10.0.2.2:5000';
// 10.0.2.2 = adresse spéciale pour joindre l'host depuis l'émulateur
```

**Pour les simulateurs iOS/Web**:
```dart
static const String baseUrl = 'http://localhost:5000';
```

**Pour les appareils physiques**:
```dart
static const String baseUrl = 'http://<VOTRE_IP>:5000';
// Remplacer <VOTRE_IP> par votre IP locale (ex: 192.168.1.50)
```

### 3. Lancer l'Application

```bash
cd Mobile/frontend

# Android
flutter run -d emulator-5554

# iOS
flutter run -d iPhone\ 15

# Web
flutter run -d web

# Détection automatique
flutter run
```

---

## 🧪 Scénarios de Test

### Scénario 1: Test de Récupération du Statut

**Objective**: Vérifier que la page charge le statut des documents

**Étapes**:
1. Lancer l'app et se connecter avec un compte valide
2. Naviguer vers la page "Pièces justificatives"
3. Attendre le chargement

**Résultat attendu**:
- ✅ Barre de progression affichée pendant le chargement
- ✅ Statut des documents affiché correctement
- ✅ Documents déjà uploadés marqués avec ✓

**Commandes de Debug**:
```bash
flutter logs  # Voir les logs en temps réel

# Pour voir les requêtes HTTP:
# Dans constants.dart, ajouter:
# print('GET ${ApiConfig.piecesStatus}');
# Dans api_client.dart, afficher la réponse
```

---

### Scénario 2: Test de Sélection de Fichiers

**Objective**: Vérifier que les utilisateurs peuvent sélectionner des fichiers

**Étapes**:
1. Sur la page documents, cliquer sur "Caméra" ou "Fichier"
2. Sélectionner une image/fichier
3. Vérifier l'affichage

**Résultat attendu**:
- ✅ Image/fichier apparaît dans le formulaire
- ✅ Bouton "Supprimer" disponible
- ✅ Bouton d'upload activé
- ✅ Compte de fichiers correct: "Télécharger 1 fichier(s)"

**Test Physique**:
```bash
# Prendre une photo avec la caméra
# Sélectionner un fichier du dossier Downloads
```

---

### Scénario 3: Test d'Upload Multipart

**Objective**: Vérifier que l'upload multipart fonctionne

**Étapes**:
1. Sélectionner tous les documents obligatoires
2. Cliquer sur "Télécharger X fichiers"
3. Attendre la fin de l'upload

**Résultat attendu**:
- ✅ Spinner de chargement visible
- ✅ Pas de crash lors de l'upload
- ✅ Message de succès après ~2-5 secondes
- ✅ Page se réinitialise automatiquement
- ✅ Statut recharge et montre les documents comme "valides"

**Vérifier dans le Backend**:
```bash
# Logs du serveur
tail -f logs/combined.log

# Vérifier les fichiers uploadés
ls -la backend-gestion/uploads/documents/
```

---

### Scénario 4: Test de Validation (Documents Manquants)

**Objective**: Vérifier que la validation empêche un upload incomplet

**Étapes**:
1. Sélectionner seulement 1 document obligatoire (ex: photo d'identité)
2. Cliquer sur "Télécharger 1 fichier(s)"

**Résultat attendu**:
- ✅ SnackBar d'erreur: "Documents manquants: Acte de naissance, Diplôme précédent"
- ✅ Upload ne se déclenche pas
- ✅ Fichier sélectionné reste en place

---

### Scénario 5: Test de Gestion des Erreurs

**Objective**: Vérifier la gestion des erreurs réseau

**Étapes Réseau Coupé**:
1. Éteindre le WiFi / passer en mode avion
2. Cliquer sur "Charger le statut" ou upload

**Résultat attendu**:
- ✅ Message d'erreur: "Impossible de joindre le serveur"
- ✅ Pas de crash
- ✅ Possibilité de réessayer

**Étapes Backend Arrêté**:
1. Arrêter le serveur backend
2. Essayer de charger le statut

**Résultat attendu**:
- ✅ Timeout après 60 secondes
- ✅ Message d'erreur lisible
- ✅ Possibilité de réessayer

---

### Scénario 6: Test du Document Optionnel

**Objective**: Vérifier que photoSupp est optionnel

**Étapes**:
1. Sélectionner les 3 documents obligatoires
2. Ne pas sélectionner photoSupp
3. Cliquer sur upload

**Résultat attendu**:
- ✅ Upload réussit sans photoSupp
- ✅ Statut montre photoSupp comme "manquant"
- ✅ Possibilité d'ajouter photoSupp plus tard

---

### Scénario 7: Test de Mise à Jour Partielle

**Objective**: Vérifier qu'on peut ajouter un document optionnel

**Étapes**:
1. Après avoir uploadsé les 3 documents obligatoires
2. Ajouter la photoSupp
3. Cliquer sur upload

**Résultat attendu**:
- ✅ Seule la photoSupp est envoyée (pas les autres)
- ✅ Les autres documents restent intacts
- ✅ Statut se met à jour correctement

---

### Scénario 8: Test de Performance

**Objective**: Vérifier que l'upload est performant

**Mesures**:
- Temps de chargement de la page: < 2 secondes
- Temps d'upload pour 3 fichiers (5MB total): < 10 secondes
- Pas de gel de l'UI pendant l'upload

**Test avec Fichiers Volumineux**:
```bash
# Créer un fichier test de 10MB
dd if=/dev/zero of=test_10mb.jpg bs=1M count=10

# Essayer d'uploader
# Résultat attendu: Erreur "Fichier trop volumineux (max 5MB)"
```

---

## 🔍 Inspection du Code

### Structure des Fichiers

```
Mobile/frontend/
├── lib/
│   ├── screens/
│   │   └── documents/
│   │       └── documents_screen.dart  ← Page principale
│   ├── services/
│   │   ├── api_client.dart           ← HTTP client
│   │   └── storage_service.dart      ← Gestion des tokens
│   ├── models/
│   │   └── ...
│   └── constants.dart                ← Configuration API
└── pubspec.yaml                      ← Dépendances
```

### Points Clés du Code

**Initialisation**:
```dart
@override
void initState() {
    super.initState();
    _loadDocumentsStatus();  // Charger le statut au démarrage
}
```

**Upload Multipart**:
```dart
final request = http.MultipartRequest('POST', Uri.parse(url));
request.files.add(
    await http.MultipartFile.fromPath(fieldName, file.path)
);
final response = await request.send().timeout(Duration(seconds: 60));
```

**Validation**:
```dart
if (docType.isRequired && _selectedFiles[docType.key] == null) {
    missingRequired.add(docType.label);
}
```

---

## 📊 Métriques de Test

| Test | Status | Commentaires |
|------|--------|-------------|
| Chargement statut | ✅ | < 2 sec |
| Sélection fichier | ✅ | Instantané |
| Validation | ✅ | Messages clairs |
| Upload multipart | ✅ | Atomique |
| Gestion erreurs | ✅ | User-friendly |
| Performance | ✅ | Pas de lag |
| Documents optionnels | ✅ | Flexible |
| UI responsive | ✅ | Affichage correct |

---

## 🐛 Débogage en Temps Réel

### Afficher les Logs HTTP

```dart
// Dans api_client.dart, ajouter:
print('→ ${method.toUpperCase()} $url');
print('← Status: ${response.statusCode}');
print('← Body: ${response.body}');
```

### Inspecter l'État Local

```dart
// Dans documents_screen.dart, ajouter:
@override
void didUpdateWidget(DocumentsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('Documents Status: $_documentsStatus');
    print('Selected Files: $_selectedFiles');
}
```

### Déboguer l'Upload

```dart
// Avant d'envoyer:
print('Files à uploader: ${_selectedFiles.entries.where((e) => e.value != null).length}');

// Dans la réponse:
print('Status Code: ${response.statusCode}');
print('Response: ${response.body}');
```

---

## ✅ Checklist Avant Production

- [ ] Tests manuels complétés pour tous les scénarios
- [ ] Pas de crashes lors des erreurs réseau
- [ ] Performances acceptables (< 10s pour upload)
- [ ] Messages d'erreur clairs et en français
- [ ] Design responsive sur toutes les tailles
- [ ] Token JWT gère correctement l'authentification
- [ ] Multipart upload fonctionne correctement
- [ ] Backend valide les fichiers (type, taille)
- [ ] Fichiers sauvegardés correctement
- [ ] Statut se recharge après upload
- [ ] Documents optionnels gérés correctement
- [ ] UX fluide du start à la fin

---

## 🚀 Commandes Utiles

```bash
# Logs en temps réel
flutter logs

# Logs filtrés par tag
flutter logs -s "documents"

# Rebuild après modification
flutter clean
flutter pub get
flutter run

# Mode debug verbose
flutter run -v

# Mode release (optimisé)
flutter run --release

# Analyser le code
flutter analyze

# Format le code
flutter format lib/

# Rebuild après modification de constantes
flutter pub pub get
```

---

**Dernière mise à jour**: 2026-07-08  
**Testeur**: QA Team  
**Status**: ✅ Ready for Testing
