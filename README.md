# frontend

A new Flutter project.

## Connexion Google sur Flutter Web

Pour utiliser le bouton Google dans le navigateur, crée un identifiant OAuth
`Client ID` de type **Web application** dans Google Cloud Console, puis ajoute
ton origine locale dans les origines JavaScript autorisées, par exemple :

- `http://localhost:3001`

Lance ensuite l'application avec ton client ID web :

```bash
flutter run -d chrome --web-hostname localhost --web-port 3001 --dart-define=GOOGLE_WEB_CLIENT_ID=ton-client-id-web.apps.googleusercontent.com
```

Par défaut, l'application pointe vers le backend Render :

```txt
https://backend-gestion-kask.onrender.com
```

Pour utiliser une autre API, passe aussi :

```bash
flutter run -d chrome --web-hostname localhost --web-port 3001 --dart-define=API_BASE_URL=https://backend-gestion-kask.onrender.com --dart-define=GOOGLE_WEB_CLIENT_ID=198209309688-ulk5udgji1kt2kv4utrf4pq36mvdfrc2.apps.googleusercontent.com
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
