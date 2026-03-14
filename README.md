# Musy

A music trivia and challenge app built with Flutter — fully offline.

## About

Musy is a fun, offline-first music trivia game where players can test their knowledge across three game modes: **Finish the Lyric**, **Guess the Artist**, and **Name the Song**. Track your streaks, compete on the local leaderboard, and manage your own question bank — all without an internet connection.

## Tech Stack

- **Flutter** & **Dart**
- **SQLite** (via `sqflite`) — stores questions, sessions, and leaderboard data
- **SharedPreferences** — stores user settings (username, theme, timer)
- **Provider** — state management

## Features

- Three game modes with timed questions
- Score tracking, streaks, and session summaries
- Local leaderboard with mode filtering
- Question Manager with full CRUD support
- Light and dark theme support
- Fully offline — no cloud services

## Project Structure

```
lib/
├── main.dart                  # App entry point and navigation shell
├── models/
│   ├── question.dart          # Question data model
│   ├── game_session.dart      # Game session data model
│   └── leaderboard_entry.dart # Leaderboard entry data model
├── screens/
│   ├── home_screen.dart       # Home / splash screen
│   ├── game_mode_screen.dart  # Game mode selection
│   ├── quiz_screen.dart       # Active quiz gameplay
│   ├── results_screen.dart    # End-of-session results
│   ├── leaderboard_screen.dart    # Local leaderboard
│   ├── question_manager_screen.dart # Question CRUD manager
│   └── settings_screen.dart   # User preferences
├── services/
│   ├── database_helper.dart   # SQLite database operations
│   └── settings_service.dart  # SharedPreferences wrapper
└── widgets/                   # Reusable UI components
```

## Screens

| # | Screen | Description |
|---|--------|-------------|
| 1 | Home | Entry point with player stats and Play button |
| 2 | Game Mode Select | Choose between the three challenge types |
| 3 | Active Quiz | Timed questions with score and streak tracking |
| 4 | Results | Session summary with high score detection |
| 5 | Leaderboard | Top scores filtered by game mode |
| 6 | Question Manager | Add, edit, and delete trivia questions |
| 7 | Settings | Username, theme, and timer preferences |

## Team

- **Raphael Omorose** — Backend, SQLite, game logic
- **Aaliyah Fievre** — UI/UX, frontend, visual polish
