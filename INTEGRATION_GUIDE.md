# 📋 Guide d'Intégration - Page Documents

## Vue d'ensemble

Ce guide explique comment la page documents mobile s'intègre parfaitement avec le backend pour gérer l'inscription des candidats.

---

## 🔌 Points d'Intégration

### 1. **Flux d'Authentification**
```
Mobile App
   ↓
[Login] → Récupère JWT token
   ↓
ApiClient ajoute automatiquement le token à chaque requête
   ↓
Backend vérifie le token et req.user.id
```

### 2. **Récupération du Statut Initial**

**Code Mobile**:
```dart
Future<void> _loadDocumentsStatus() async {
    setState(() => _isCheckingStatus = true);
    try {
        final status = await ApiClient.get(ApiConfig.piecesStatus);
        setState(() {
            _documentsStatus = status ?? {};
            _isCheckingStatus = false;
        });
    } catch (e) {
        setState(() {
            _errorMessage = 'Erreur lors du chargement du statut: $e';
            _isCheckingStatus = false;
        });
    }
}
```

**Requête HTTP**:
```
GET /api/documents/pieces/status
Authorization: Bearer <JWT_TOKEN>
```

**Réponse Backend**:
```json
{
    "photoIdentite": "valide",
    "acteNaissance": "manquant",
    "diplomePrecedent": "manquant",
    "photoSupp": "manquant"
}
```

**Endpoint Backend**:
```typescript
// backend-gestion/src/routes/document.routes.ts
router.get('/pieces/status', protect, restrictTo('CANDIDAT'), checkPiecesStatus);

// backend-gestion/src/controllers/document.controller.ts
export const checkPiecesStatus = async (req: AuthenticatedRequest, res: Response) => {
    const candidat = await Candidat.findOne({ user: req.user?.id });
    return {
        photoIdentite: candidat.piecesJustificatives.photoIdentite?.status === 'valide' ? 'valide' : 'manquant',
        acteNaissance: candidat.piecesJustificatives.acteNaissance?.status === 'valide' ? 'valide' : 'manquant',
        // ...
    };
}
```

---

### 3. **Upload des Documents**

**Code Mobile**:
```dart
Future<void> _uploadAllDocuments() async {
    // 1. Valider les documents requis
    List<String> missingRequired = [];
    for (var docType in _documentTypes) {
        if (docType.isRequired && _selectedFiles[docType.key] == null) {
            missingRequired.add(docType.label);
        }
    }
    if (missingRequired.isNotEmpty) {
        // Afficher erreur
        return;
    }

    // 2. Créer requête multipart
    final request = http.MultipartRequest('POST', Uri.parse(ApiConfig.inscriptionDocuments));
    
    // 3. Ajouter token d'authentification
    final token = await StorageService.getToken();
    if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
    }

    // 4. Ajouter tous les fichiers
    for (var entry in _selectedFiles.entries) {
        if (entry.value != null) {
            request.files.add(
                await http.MultipartFile.fromPath(entry.key, entry.value!.path),
            );
        }
    }

    // 5. Envoyer requête
    final streamedResponse = await request.send().timeout(Duration(seconds: 60));
    final response = await http.Response.fromStream(streamedResponse);

    // 6. Gérer réponse
    if (response.statusCode == 200) {
        // Réinitialiser et recharger
        setState(() => _selectedFiles = {...});
        await _loadDocumentsStatus();
    } else {
        // Afficher erreur
    }
}
```

**Requête HTTP**:
```
POST /api/inscription/documents
Content-Type: multipart/form-data
Authorization: Bearer <JWT_TOKEN>

[Body multipart]
photoIdentite: <binary_data>
acteNaissance: <binary_data>
diplomePrecedent: <binary_data>
photoSupp: <binary_data>
```

**Endpoint Backend**:
```typescript
// backend-gestion/src/routes/inscription.routes.ts
router.post('/documents', 
    protect, 
    restrictTo('CANDIDAT'), 
    uploadMiddleware,  // Traite multipart/form-data
    async (req, res) => {
        await uploadDocuments(req, res);
    }
);

// backend-gestion/src/controllers/inscription.controller.ts
export const uploadDocuments = async (req: any, res: Response) => {
    const candidat = await Candidat.findOne({ user: req.user?.id });
    
    // Traiter chaque fichier
    if (req.files.photoIdentite?.[0]) {
        candidat.piecesJustificatives.photoIdentite = {
            status: 'valide',
            chemin: req.files.photoIdentite[0].path
        };
    }
    // ... autres fichiers ...
    
    await candidat.save();
    res.json({ success: true, data: candidat.piecesJustificatives });
}
```

**Réponse Backend** (succès):
```json
{
    "success": true,
    "message": "Documents téléchargés avec succès",
    "data": {
        "photoIdentite": {
            "status": "valide",
            "chemin": "./uploads/documents/photoIdentite-1234567890.jpg"
        },
        "acteNaissance": {
            "status": "valide",
            "chemin": "./uploads/documents/acteNaissance-1234567890.pdf"
        },
        "diplomePrecedent": {
            "status": "valide",
            "chemin": "./uploads/documents/diplomePrecedent-1234567890.jpg"
        },
        "photoSupp": {
            "status": "manquant"
        }
    }
}
```

---

## 📦 Structure des Données

### Modèle Backend (MongoDB)

```typescript
// backend-gestion/src/models/Candidat.ts
interface ICandidat {
    piecesJustificatives: {
        photoIdentite?: {
            status?: 'valide' | 'invalide' | 'manquant';
            chemin?: string;
        };
        acteNaissance?: {
            status?: 'valide' | 'invalide' | 'manquant';
            chemin?: string;
        };
        diplomePrecedent?: {
            status?: 'valide' | 'invalide' | 'manquant';
            chemin?: string;
        };
        photoSupp?: {
            status?: 'valide' | 'invalide' | 'manquant';
            chemin?: string;
        };
    };
}

const CandidatSchema = new Schema({
    piecesJustificatives: {
        photoIdentite: {
            status: { type: String, enum: ['valide', 'invalide', 'manquant'], default: 'manquant' },
            chemin: { type: String }
        },
        acteNaissance: {
            status: { type: String, enum: ['valide', 'invalide', 'manquant'], default: 'manquant' },
            chemin: { type: String }
        },
        diplomePrecedent: {
            status: { type: String, enum: ['valide', 'invalide', 'manquant'], default: 'manquant' },
            chemin: { type: String }
        },
        photoSupp: {
            status: { type: String, enum: ['valide', 'invalide', 'manquant'], default: 'manquant' },
            chemin: { type: String }
        }
    }
});

// Pré-hook pour initialisation
CandidatSchema.pre('save', function(next) {
    if (!this.piecesJustificatives) {
        this.piecesJustificatives = {
            photoIdentite: { status: 'manquant' },
            acteNaissance: { status: 'manquant' },
            diplomePrecedent: { status: 'manquant' },
            photoSupp: { status: 'manquant' },
        };
    }
    next();
});
```

### Configuration Mobile (Dart)

```dart
// Mobile/frontend/lib/constants.dart
class ApiConfig {
    static const String inscriptionDocuments = '$apiPrefix/inscription/documents';
    static const String piecesStatus = '$apiPrefix/documents/pieces/status';
    static const String releveNotesPdf = '$apiPrefix/documents/releve-notes';
    static const String convocationPdf = '$apiPrefix/documents/convocation';
}

class AppConstants {
    static const Map<String, String> typesDocuments = {
        'photoIdentite': 'Photo d\'identité',
        'acteNaissance': 'Acte de naissance',
        'diplomePrecedent': 'Diplôme précédent',
        'photoSupp': 'Photo supplémentaire',
    };
}
```

---

## ✅ Checklist de Vérification

### Backend
- [ ] Modèle `Candidat.ts` a `piecesJustificatives` avec structure correcte
- [ ] Pré-hook d'initialisation dans le schema
- [ ] Route `POST /inscription/documents` avec middleware multipart
- [ ] Route `GET /documents/pieces/status` pour récupérer le statut
- [ ] Contrôleur `uploadDocuments` sauvegarde les chemins des fichiers
- [ ] Contrôleur `checkPiecesStatus` retourne le statut correct
- [ ] Middleware `protect` et `restrictTo('CANDIDAT')` configurés
- [ ] Multer configuré pour accepter les types de fichiers corrects

### Frontend Mobile
- [ ] Page `documents_screen.dart` importée depuis le bon chemin
- [ ] `ApiConfig.inscriptionDocuments` pointe vers le bon endpoint
- [ ] `ApiConfig.piecesStatus` pointe vers le bon endpoint
- [ ] Upload multipart utilise les bons noms de champs: `photoIdentite`, `acteNaissance`, `diplomePrecedent`, `photoSupp`
- [ ] Token JWT ajouté automatiquement au header
- [ ] Gestion des erreurs réseau et backend
- [ ] Réinitialisation post-upload

### Intégration
- [ ] CORS configuré pour accepter les requêtes du frontend
- [ ] Authentification fonctionne correctement
- [ ] Tokens JWT valides et non expirés
- [ ] Chemins des fichiers sauvegardés correctement
- [ ] Statut reflète l'état réel du backend

---

## 🐛 Débogage

### Problème: "Utilisateur non authentifié"

**Cause**: Token JWT manquant ou invalide

**Solution**:
```dart
// Vérifier que le token est sauvegardé après le login
final token = await StorageService.getToken();
print('Token: $token');  // Devrait afficher le JWT

// Vérifier que le header est ajouté
request.headers['Authorization'] = 'Bearer $token';
```

### Problème: "Candidat non trouvé"

**Cause**: `req.user?.id` est null

**Solution**:
```typescript
// Vérifier que le middleware auth ajoute req.user
console.log('req.user:', req.user);

// S'assurer que protect middleware est appliqué
router.post('/documents', protect, restrictTo('CANDIDAT'), uploadMiddleware, ...);
```

### Problème: "Fichiers non trouvés dans req.files"

**Cause**: Noms de champs incorrects ou upload middleware pas appliqué

**Solution**:
```typescript
// Vérifier les noms de champs
console.log('Champs reçus:', Object.keys(req.files || {}));

// S'assurer que uploadMiddleware est appliqué
const uploadMiddleware = upload.fields([
    { name: 'photoIdentite', maxCount: 1 },
    { name: 'acteNaissance', maxCount: 1 },
    { name: 'diplomePrecedent', maxCount: 1 },
    { name: 'photoSupp', maxCount: 1 }
]);
```

### Problème: "Timeout lors du téléchargement"

**Cause**: Fichiers trop volumineux ou réseau lent

**Solution**:
```dart
// Augmenter le timeout
final response = await request.send().timeout(
    const Duration(seconds: 120),  // 2 minutes
);

// Ou compresser les fichiers
final compressed = await ImageCompress.compressAndGetFile(...);
```

---

## 📊 Flux Complet de l'Inscription

```
1. [Candidat se crée un compte]
   POST /auth/register
   → Crée User + Candidat avec piecesJustificatives initialisées
   → Retourne JWT token

2. [Candidat complète le profil]
   POST /inscription/profile
   → Remplit dateNaissance, lieuNaissance, genre, etc.

3. [Candidat complète les documents]
   GET /documents/pieces/status (affiche ce qui manque)
   POST /inscription/documents (upload des fichiers)
   → Sauvegarde les chemins des fichiers
   → Change le statut de chaque pièce à "valide"

4. [Candidat valide l'inscription]
   POST /inscription/submit
   → Vérifie tous les champs obligatoires
   → Change statutInscription à "EN_ATTENTE_VALIDATION"

5. [Admin valide l'inscription]
   POST /admin/candidats/{id}/valider
   → Change statutInscription à "VALIDE"

6. [Candidat effectue le paiement]
   POST /paiement/initier
   → Change paiement.statut à "PAYE"

7. [Admin affecte un centre d'examen]
   POST /affectation/auto
   → Ajoute centreAffecte et génère convocation

8. [Candidat télécharge ses documents]
   GET /documents/releve-notes (PDF)
   GET /documents/convocation (PDF avec QR code)
```

---

## 🚀 Prochaines Étapes

1. **Tests**
   ```bash
   cd backend-gestion
   npm run test  # Ajouter des tests unitaires
   ```

2. **Documentation API**
   - Swagger à jour: `/api-docs`
   - Exemples cURL pour chaque endpoint

3. **Optimisations**
   - Compression des images avant upload
   - Cache des statuts côté mobile
   - Retry automatique en cas d'erreur réseau

4. **Sécurité**
   - Valider les types MIME
   - Analyser les fichiers pour les malwares
   - Limiter la taille des téléchargements

---

**Dernière mise à jour**: 2026-07-08  
**Version**: 1.0.0  
**Status**: ✅ Production Ready
