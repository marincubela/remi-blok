# Kartaški blok – Remi scorekeeper

Kartaški blok is a simple Flutter app for tracking scores in the Remi card game.
It lets you manage players, record scores across rounds, and automatically
calculate totals, with the full game state persisted locally on the device.

## Features

- **Dynamic players**: add and remove players (2–7 players supported).
- **Rounds & scores**: add/remove rounds, enter positive or negative scores.
- **Flexible score display**:
  - Round score with cumulative badge.
  - Cumulative score with round badge.
  - Round-only view.
  - Cumulative-only view.
- **Automatic totals**: per-player totals shown in the bottom row.
- **Persistence**: game state is saved to local storage and restored on app start.

## Architecture

- `main.dart` – App entry point, sets up `MaterialApp` and injects storage.
- `remi.dart` – `RemiPage` UI with the score table and controls.
- `remi_repository.dart` – Domain model for players, rounds, and score logic.
- `remi_storage.dart` – File-based JSON persistence using `path_provider`.

## Running the app

From the project root:

```bash
flutter pub get
flutter run
```

## Testing

Run unit and widget tests with:

```bash
flutter test
```
