# Musy 🎵

**A fully offline music trivia app built with Flutter.**

Musy challenges you with three game modes, timed questions, streak tracking, and a local leaderboard — all without needing an internet connection.

---

## Team

| Name | Role |
|------|------|
| **Raphael Omorose** | Backend development, SQLite schema, game logic, CRUD |
| **Aaliyah Fievre** | UI/UX design, Flutter frontend, navigation, visual polish |

**Course:** CSC 4360 – Mobile App Development · Section 10111 · Team Rapliyah

---

## Features

- **Three game modes:** Finish the Lyric, Guess the Artist, Name the Song
- **Timed questions** with adjustable timer (15–60 seconds)
- **Scoring system:** +10 per correct answer, +5 streak bonus every 3 in a row
- **Recommendation engine:** prioritizes frequently-missed questions (30% weak question mixing)
- **Local leaderboard** with mode filtering and tie handling
- **Question Manager** with full CRUD (add, edit, delete questions)
- **Settings:** username, dark/light theme toggle, timer duration
- **30 built-in trivia questions** seeded on first launch
- **Dark mode** support via Provider + ThemeController
- **Fully offline** — SQLite + SharedPreferences, no cloud services

---

## Screens

| # | Screen | Purpose |
|---|--------|---------|
| 1 | Home | Branding, player stats, Play button, settings access |
| 2 | Game Mode Select | Choose between 3 challenge types, view best scores |
| 3 | Active Quiz | Timed gameplay with score/streak/timer cards |
| 4 | Results | Final score, accuracy, streak, high-score detection |
| 5 | Leaderboard | Ranked scores with mode filter chips |
| 6 | Question Manager | Add/edit/delete trivia questions |
| 7 | Settings | Username, dark mode, timer duration |

---

## Tech Stack

- **Flutter** (Dart)
- **sqflite** — SQLite database for questions, sessions, leaderboard, attempts
- **shared_preferences** — user settings (username, theme, timer)
- **provider** — state management for theme switching
- **Material 3** — Material Design with `useMaterial3: true`

---

## Database Schema

```
questions
├── id (INTEGER PK)
├── questionText (TEXT)
├── questionType (TEXT) — "Finish the Lyric" / "Guess the Artist" / "Name the Song"
├── difficulty (TEXT) — Easy / Medium / Hard
├── correctAnswer (TEXT)
├── optionA–D (TEXT)

sessions
├── id (INTEGER PK)
├── gameMode (TEXT)
├── score (INTEGER)
├── totalQuestions / correctAnswers / highestStreak (INTEGER)
├── datePlayed (TEXT)

leaderboard
├── id (INTEGER PK)
├── playerName (TEXT)
├── gameMode (TEXT)
├── score (INTEGER)
├── datePlayed (TEXT)

question_attempts
├── id (INTEGER PK)
├── questionId (INTEGER FK → questions.id)
├── wasCorrect (INTEGER) — 0 or 1
├── datePlayed (TEXT)
```

---

## Installation

```bash
# Clone the repo
git clone https://github.com/OfficialEseosa/Musy.git
cd Musy

# Install dependencies
flutter pub get

# Run in debug mode
flutter run

# Build release APK
flutter build apk --release
```

The APK will be at `build/app/outputs/flutter-apk/app-release.apk`.

---

## Project Structure

```
lib/
├── main.dart                  # App entry, theme, navigation
├── models/
│   ├── question.dart          # Question data model
│   ├── game_session.dart      # Session data model
│   └── leaderboard_entry.dart # Leaderboard data model
├── screens/
│   ├── home_screen.dart       # Home with stats + Play
│   ├── game_mode_screen.dart  # Mode selection cards
│   ├── quiz_screen.dart       # Timed quiz gameplay
│   ├── results_screen.dart    # Post-quiz results
│   ├── leaderboard_screen.dart# Ranked scores
│   ├── question_manager_screen.dart # CRUD for questions
│   └── settings_screen.dart   # App preferences
└── services/
    ├── database_helper.dart   # SQLite singleton + all queries
    ├── settings_service.dart  # SharedPreferences wrapper
    └── theme_controller.dart  # Dark/light mode ChangeNotifier
```

---

## Usage Guide

1. **Launch the app** — 30 trivia questions are seeded automatically on first run
2. **Tap Play** → choose a game mode → answer 10 timed questions
3. **Earn points** — +10 per correct answer, +5 bonus every 3 correct in a row
4. **View results** — see your score, accuracy, streak, and whether you set a high score
5. **Check the Leaderboard** — filter by mode, see rankings
6. **Manage Questions** — add your own trivia via the Question Manager tab
7. **Customize** — change username, toggle dark mode, adjust timer in Settings

---

## Known Issues

- Landscape mode uses the same portrait layout (content scrolls naturally but isn't optimized for wide screens)
- Timer continues running briefly if the app is backgrounded mid-quiz

---

## Future Enhancements

- Sound effects and haptic feedback on correct/incorrect answers
- Difficulty-based scoring multipliers
- Import/export questions as JSON
- Animated transitions between quiz questions
- Cloud sync for cross-device leaderboards


