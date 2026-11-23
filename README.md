# Flash-Ed

Flash-Ed is a student-focused learning app for materials, flashcards, interactive
review, quizzes, and study progress.

## Architecture

The app uses feature-based presentation and data layers with shared application
services. UI state belongs in Riverpod providers, navigation in GoRouter, and
data access behind repositories so Firebase can be replaced in tests.

```text
lib/
  app.dart
  main.dart
  core/
    constants/
    routes/
    services/
    theme/
    utils/
    widgets/
  features/
    authentication/{data,domain,presentation}/
    bookmarks/presentation/
    dashboard/presentation/
    flashcards/{data,domain,presentation}/
    flashcard_generator/{data,domain,presentation}/
    materials/{data,domain,presentation}/
    profile/presentation/
    progress/{data,presentation}/
    quizzes/{data,domain,presentation}/
    sections/presentation/
    study_mode/presentation/
```

The current app includes Firebase email/password registration, login and reset
email screens, auth-gated navigation, Firebase Storage/Firestore material
uploads and bookmarks, local per-account flashcard-set CRUD, study sessions,
quizzes, and progress summaries. Flashcard sets and activity are stored on the
device with `SharedPreferencesAsync`; they are not yet synced between devices.
Document-based AI generation and admin management still need their later
feature phases. No sample progress is shown as real user data.

## Dependencies

The project declares the packages for the planned features:

- `flutter_riverpod`, `go_router`: state management and navigation.
- `url_launcher`: open material download links in the platform viewer/browser.
- `google_fonts`: Inter typography.
- `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`,
  `cloud_functions`: Firebase services.
- `image_picker`, `file_picker`, `flutter_pdfview`, `pdf`, `path_provider`:
  profile images, document selection, PDF viewing, and local file handling.
- `fl_chart`, `intl`, `uuid`, `shared_preferences`: progress visualizations,
  dates, identifiers, and local preferences.
- `cached_network_image`, `flutter_local_notifications`, `http`: image caching,
  notifications, and API communication.

Resolved versions are recorded in `pubspec.lock`. To fetch packages:

```sh
flutter pub get
```

On Windows, Flutter plugins may require Developer Mode to be enabled to create
plugin symlinks.

## Firebase setup (Phase 2)

1. Create a Firebase project and register each target app (Android, iOS, and
   web, as applicable).
2. Install and authenticate the Firebase CLI and FlutterFire CLI, then run
   `flutterfire configure` from this repository. Firebase platform config
   includes project identifiers, not server credentials; enforce security with
   Firebase rules and never embed AI-provider secrets in the client.
3. Configure the non-secret Firebase app identifiers as Dart defines:

   ```text
   FIREBASE_API_KEY
   FIREBASE_PROJECT_ID
   FIREBASE_MESSAGING_SENDER_ID
   FIREBASE_ANDROID_APP_ID
   FIREBASE_IOS_APP_ID
   FIREBASE_WEB_APP_ID
   FIREBASE_AUTH_DOMAIN       (web)
   FIREBASE_STORAGE_BUCKET
   FIREBASE_IOS_BUNDLE_ID     (Apple targets)
   ```

   Obtain these values from FlutterFire CLI output (`firebase_options.dart`)
   in the Firebase console. Supply them with `--dart-define=KEY=value` when
   launching/building. Enable the Email/Password provider in Firebase
   Authentication. When required identifiers are absent, sign-in and
   registration show an explicit Firebase setup message.

   For example, run with your project's values (do not commit real values in
   shell scripts or source files):

   ```sh
   flutter run --dart-define=FIREBASE_API_KEY=<api-key> --dart-define=FIREBASE_PROJECT_ID=<project-id> --dart-define=FIREBASE_MESSAGING_SENDER_ID=<sender-id> --dart-define=FIREBASE_ANDROID_APP_ID=<android-app-id> --dart-define=FIREBASE_STORAGE_BUCKET=<bucket-name>
   ```

   Include the matching platform app ID for iOS or web builds. Registration
   sends a verification email; students must verify before using protected
   data. Password reset uses Firebase's password reset email flow.
4. Create a Cloud Firestore database, enable Storage, and deploy rules/indexes:

   ```sh
   firebase deploy --only firestore:rules,firestore:indexes,storage
   ```

   Registration creates a student profile at `users/{uid}`. Do not assign
   administrator custom claims from the app. Student material uploads are
   private and limited to PDF/TXT files up to 20 MB.
5. Deploy the AI generation endpoint as a Cloud Function or trusted backend.
   Store its provider credential in server-side secret configuration only;
   never add the secret to Flutter, Firestore, or source control.

Until Firebase is configured, registration, login, email verification, reset
email, material uploads, bookmarks, and remote profile creation are not active.
The app still runs without Firebase: choose **Continue without Firebase** on
the login screen to use guest mode. Flashcard CRUD, study sessions, quizzes,
and progress are stored locally on that device and are not backed up or synced.
Guest mode does not create an account or store a password. Offline password-
based accounts are deliberately not provided because a local-only password
system would not be a secure substitute for Firebase Authentication.

The Android project compiles against SDK 37 and uses core-library desugaring to
support the selected notifications package. Install Android SDK Platform 37
when building Android targets.

## Firestore data design

Use the authenticated UID as the user document ID. Private user-owned records
carry `userId` and are only readable/writable by their owner:

- `users/{uid}`: name, email, course, year level, image URL, preferences.
- `subjects/{subjectId}`: subject name, description, timestamps.
- `materials/{materialId}`: metadata, Storage path, uploader, visibility,
  subject, and timestamps.
- `flashcardSets/{setId}`: owner, title, description, subject, source material,
  and timestamps.
- `flashcards/{cardId}`: owner, set ID, front/back, difficulty, and timestamps.
- `studySessions/{sessionId}` and `quizzes/{quizId}`: owner, set ID, results,
  and server completion timestamps.
- `bookmarks/{bookmarkId}` and `notifications/{notificationId}`: owner-linked
  records and timestamps.

Prefer subcollections for cards under sets if per-set reads/deletes are more
efficient for the final usage patterns. Enforce published material read access,
private ownership, and admin-only publishing in Firestore and Storage rules.
Administrator authorization must use trusted custom claims set by a privileged
backend—not a client-editable `role` field. Add composite indexes for actual
query shapes as they are introduced.

## Implementation roadmap

1. Project setup and design system — done
2. Firebase email/password authentication and protected navigation — implemented
3. Student dashboard and navigation — implemented
4. Learning materials library, private uploads, and bookmarks — implemented
5. Manual flashcard creator and local CRUD — implemented
6. Document-based flashcard generation through a secure backend — pending
7. Interactive flashcard study mode and local session records — implemented
8. Quiz module, scoring, and local result records — implemented
9. Progress summaries and bookmarks — implemented
10. Profile and settings — sign-out and password reset implemented
11. Admin functionality with server-validated roles — pending
12. Tests, Firebase rule validation, and optimization — in progress

Run with `flutter run`. Firebase defines are optional: without them, choose
guest mode to use local study features. For online registration, login, and
cloud materials, provide the Firebase Dart defines above. For an Android
release build, use `flutter build apk --release` with those same defines.

Run the checks with:

```sh
flutter analyze
flutter test
```
