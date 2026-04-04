# Classmate

[![Flutter](https://img.shields.io/badge/Flutter-App-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Material 3](https://img.shields.io/badge/Material%203-Enabled-6750A4?style=for-the-badge)](https://m3.material.io)
[![License](https://img.shields.io/badge/License-AGPL%20v3-A42E2B?style=for-the-badge)](LICENSE)

[中文 README](README.md)

Classmate is a Flutter timetable app with multi-timetable management, shared period-time sets, course editing, conflict display, and timetable data import/export.

## Features

- Creates a blank timetable automatically on first launch and loads built-in default period times
- Multi-timetable management: create, switch, rename, and delete timetables
- Shared period-time sets: select, create, edit, and reuse them across multiple timetables
- Weekly timetable view with quick week jumping
- Desktop support for week switching with arrow keys and horizontal mouse dragging
- Add, edit, and delete courses
- Course details view with conflict handling
- Import, export, share, and save one or more timetable JSON files
- Cross-platform support for Android, Windows, and Web

## Default first-run data

On first launch, the app automatically creates:

- A default blank timetable named `空白课表`
- A built-in default period-time set loaded from [assets/default_period_times.json](assets/default_period_times.json)

If local data already exists, the app loads the saved data first.

## Main screens

### Home screen

- Shows the weekly timetable
- Lets you jump to any week from the top bar
- Opens course details and conflict info when tapping a course
- Lets you quickly add a course for a weekday by long-pressing an empty area
- Provides a drawer for switching, editing, and creating timetables

### Settings screen

- Set the semester start date
- Select a period-time set
- Create or edit period-time sets directly inside the selection dialog
- Import and export timetable data
- Open the GitHub repository

## Import and export

- Import one or more timetables
- Export one or more timetables as a JSON file
- When importing a single timetable, choose either "Import as new timetable" or "Replace current timetable"
- Period-time set references and ID conflicts are normalized automatically during import

## Tech stack

- Flutter
- Dart
- Provider
- Material 3

## Project structure

```text
lib/
├─ data/         # Local storage and platform adapters
├─ models/       # Timetable, course, and period-time models
├─ providers/    # State management and import/export logic
├─ screens/      # Screens such as home, settings, and period-time editor
├─ services/     # Export and sharing services
└─ widgets/      # Timetable grid, course editor, and detail sheets
```

## Run the project

### Install dependencies

```bash
flutter pub get
```

### Start the app

```bash
flutter run
```

## Entry points

- App entry: [lib/main.dart](lib/main.dart)
- State management: [lib/providers/timetable_provider.dart](lib/providers/timetable_provider.dart)
- Home screen: [lib/screens/home_screen.dart](lib/screens/home_screen.dart)
- Settings screen: [lib/screens/settings_page.dart](lib/screens/settings_page.dart)

## Open-source license

This project is licensed under the [GNU Affero General Public License v3.0](LICENSE).

Bundled launcher icon assets include third-party licensed material. See [NOTICE](NOTICE) for details.
