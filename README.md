# Studyy Buddy

A Flutter quiz app for teachers and students. Material 3, orange brand theme,
light and dark mode.

## Features

- **Animated splash screen** - the logo springs in over ripples, the name
  types itself out, then the app opens sign-up, login or home.
- **Animated sign up / login / forgot password** - drifting background,
  hero logo, staggered field entrance, shake on error, a button that morphs
  into a spinner, a password strength meter and a 3-step reset flow that ends
  in a drawn check mark.
- **Roles** - join as a **teacher** or a **student**.
  - Teachers write multiple-choice quizzes (2-6 options per question), see
    every student's attempts and average score, preview and delete quizzes.
  - Students solve teacher quizzes, see their best score and recent results,
    and can play the built-in Flutter / Dart / Git practice topics.
- **Sign in with Google** on both the sign-up and login screens. First-time
  Google users pick a role.
- **App icon** for Android (adaptive), iOS, web, Windows and macOS.

Accounts, quizzes and results are stored on the device with
`shared_preferences`. Passwords are salted and hashed (SHA-256), never stored
in plain text. Because there is no server, quizzes are shared between users
of the same device, and "forgot password" resets the password on the device.

## Getting started

```bash
flutter pub get
flutter run
```

New users start on the sign-up screen, then log in.

## Google sign-in setup

Google sign-in needs OAuth client IDs from Google Cloud Console:

1. Create an **Android** OAuth client for package `com.example.activity_gsp`
   with your debug keystore's SHA-1 (`cd android && ./gradlew signingReport`).
2. Create a **Web application** OAuth client and copy its client ID.
3. Run with that web client ID:

```bash
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id>.apps.googleusercontent.com
```

On iOS also pass `--dart-define=GOOGLE_CLIENT_ID=<ios-client-id>` and add the
reversed client ID URL scheme to `ios/Runner/Info.plist`. Without this setup
the button shows a friendly "not configured" message instead of crashing.

## App icon

The icon is drawn by `tool/generate_icon.dart`. To regenerate:

```bash
dart run tool/generate_icon.dart
dart run flutter_launcher_icons
```

## Checks

```bash
flutter analyze
flutter test
```
