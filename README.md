# Ability Link

Global Flutter accessibility platform with Firebase Auth + Firestore.

## Run

\`\`\`bash
flutter pub get
flutter run
\`\`\`

## Firebase

- Project: abilitylink-3ac64
- Package: com.abilitylink.app
- Email/password Auth enabled
- Firestore created + rules deployed

## Flow

1. Splash → Create Account / Login
2. Auth creates users/{uid} stub
3. Profile steps save to Firestore
4. Home when onboardingComplete

## Google Sign-In

Enable Google in Firebase Auth console, add Android SHA-1, then re-run flutterfire configure if needed.
