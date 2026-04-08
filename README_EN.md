# Classmate

[![Flutter](https://img.shields.io/badge/Flutter-App-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Material 3](https://img.shields.io/badge/Material%203-Enabled-6750A4?style=for-the-badge)](https://m3.material.io)
[![License](https://img.shields.io/badge/License-AGPL%20v3-A42E2B?style=for-the-badge)](LICENSE)

[中文 README](README.md)

Classmate is a Flutter timetable app that currently supports multi-timetable management, reusable period-time sets, theme settings, school site management, and timetable import from school webpages or pasted HTML source.

## Features

- Multi-timetable management: create, switch, edit, and delete timetables
- Course editing: edit course name, location, teacher, weeks, time, and linked periods
- Period-time sets: reuse, edit, import, export, and share them across multiple timetables
- Theme settings: light / dark / follow system, preset theme colors, and custom colors
- School site management: add, edit, delete, and import or export school-site JSON entries
- School webpage / HTML import: open the school site in-app and import the current page, or paste HTML manually
- Import preview: review parsed results before import and choose the period-time set and import mode
- Data import/export: import, export, and share timetable, period-template, and school-site JSON files

Welcome to submit PRs to expand `assets/school_sites.json` with more school site entries.

## Screenshots

<table>
  <tr>
    <td align="center"><img src="docs/screenshots/s1.png" alt="Home" width="240"></td>
    <td align="center"><img src="docs/screenshots/s2.png" alt="Course details" width="240"></td>
    <td align="center"><img src="docs/screenshots/s3.png" alt="Settings" width="240"></td>
    <td align="center"><img src="docs/screenshots/s4.png" alt="Edit period time set" width="240"></td>
  </tr>
  <tr>
    <td align="center">Home</td>
    <td align="center">Course details</td>
    <td align="center">Settings</td>
    <td align="center">Edit period time set</td>
  </tr>
</table>

## School import backend

The project includes a PHP relay endpoint: [web/api.php](web/api.php). The in-app school webpage import endpoint is read from [lib/config/app_config.dart](lib/config/app_config.dart), and can be overridden with `--dart-define=SCHOOL_IMPORT_API_BASE_URL=your-endpoint`.

### Backend configuration

You need to edit the configuration block at the top of `web/api.php`:

- `$relayUrl`: upstream AI API endpoint
- `$relayToken`: your API key
- `$model`: model name to use
- `$timeoutSeconds`: request timeout, currently 120 seconds by default
- `$sourceByteLimit`: max submitted content size, currently 300KB by default
- `$maxParsesPerIpPerDay`: max parsing requests per IP per day, currently 5 by default

### Current backend behavior

- Forwards parsing requests through your own PHP service instead of exposing the upstream key in the client
- Returns a unified JSON response so the client can show parsed results and error messages directly
- Enforces submitted-content size limits and per-IP daily parsing limits
- Supports both school webpage import and pasted HTML import
- Submits page content, optional page title, page URL, and the current app language to the parsing endpoint

## Project structure

```text
lib/
├─ config/       # App configuration and default API URL
├─ models/       # Timetable, course, school-site, and import response models
├─ providers/    # State management and import/export logic
├─ screens/      # Screens such as home, settings, and school-site management
├─ services/     # Export, sharing, import API, and local storage services
└─ widgets/      # Timetable grid, course editor, and import preview widgets

web/
└─ api.php
```

## Privacy policy

Timetables, timetable settings, period-time sets, and school-site configuration are stored locally on your device or in the browser by default, and are not automatically uploaded to the developer's server.
Only when you actively use features such as import, webpage parsing, external links, or sharing will the app read related content or hand the corresponding operation off to the system.

The full privacy policy can be viewed in the app under `Settings → Privacy Policy`.

## Open-source license and third-party notices

- The source code is licensed under the [GNU Affero General Public License v3.0](LICENSE)
- Bundled launcher icon and related platform icon assets include third-party licensed material; see [NOTICE](NOTICE)
- Flutter package and third-party library licenses can be viewed in the app under `Settings → Open-source licenses`
