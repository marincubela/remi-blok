# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter card game scorekeeper app called "Kartaški blok" (Card Block) for tracking scores in a Remi card game. The app allows players to track scores across multiple rounds with persistent storage.

## Common Commands

- `flutter run` - Run the app in development mode
- `flutter build apk` - Build Android APK
- `flutter build ios` - Build iOS app  
- `flutter test` - Run tests
- `flutter analyze` - Run static analysis and linting
- `flutter pub get` - Install dependencies
- `flutter pub upgrade` - Upgrade dependencies
- `flutter pub run flutter_launcher_icons` - Generate app icons

## Architecture

The app follows a simple Flutter architecture:

### Core Components
- **main.dart**: Entry point, sets up MaterialApp with red color scheme
- **remi.dart**: Main UI page (RemiPage) containing the scorecard table
- **remi_repository.dart**: Business logic for managing players and scores
- **remi_storage.dart**: Persistent storage using local file system

### Data Flow
1. RemiStorage handles reading/writing game state to local JSON file
2. RemiRepository manages game state (players, rounds, scores)
3. RemiPage provides UI for score entry and game management
4. All state changes automatically persist via RemiStorage

### Key Features
- Dynamic player management (2-7 players)
- Score tracking across multiple rounds
- Automatic total calculation
- Persistent storage between app sessions
- Cross-platform support (Android, iOS, Web, Desktop)

## Dependencies
- `path_provider` for local file storage
- `flutter_launcher_icons` for app icon generation
- Standard Flutter/Dart packages only