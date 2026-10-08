# EC QUIZ

A real-time, interactive multiplayer quiz game application built with Flutter & Firebase.

Project Console: https://console.firebase.google.com/project/quiz-game-app-3c75d/overview
Hosting URL: https://quiz-game-app-3c75d.web.app

Features:
- **Live Multiplayer Contests**: Host and join Kahoot-style real-time quiz battles with 6-character room codes and QR code scanning.
- **Dynamic Leaderboards & Live Scores**: Real-time Firestore sync for answers, streaks, speed bonuses, and podium finishes.
- **Solo Practice Mode**: Offline & single-player speed quizzes across general trivia, science, and coding.
- **Quiz Studio & Builder**: Create custom quizzes with multiple choice, true/false, multiple select, ordering, and numeric question types.
- **Rich Audio & Sound Effects**: Synthesized audio feedback for correct/incorrect answers, countdown timers, button clicks, and looping background music with automatic mute toggles.
- **Player Profiles & Career Stats**: Custom avatars, total points, victories, contests played, and win rates dynamically tracked and persisted in Cloud Firestore.
- **Light & Dark Theme**: Built-in support for multiple color schemes and theme modes.

## Tech Stack
- **Framework**: Flutter (Web, Android, iOS, Desktop)
- **State Management**: Riverpod (`flutter_riverpod`)
- **Backend / DB**: Firebase Cloud Firestore & Firebase Auth
- **Audio**: `audioplayers`
- **Routing**: `go_router`

## Getting Started

1. **Install dependencies**:
   ```bash
   flutter pub get
   ```

2. **Run tests**:
   ```bash
   flutter test
   ```

3. **Run the app**:
   ```bash
   flutter run
   ```
