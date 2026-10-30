# AGENT.md - Wordsy Flutter Notes App Architecture & Coding Guidelines

## 1. Role & Directives for Coding Agents

* **Strict Adherence:** You must follow the file structure, database schema, and state management rules outlined in this document.
* **No Shortcuts:** Do not use placeholder comments or dummy implementations for core features unless explicitly instructed.
* **Clean Code:** Write modular, well-commented, null-safe Dart code using Flutter and Riverpod best practices.

---

## 2. Project Overview & Product Vision

**Wordsy** is an iOS-inspired, feature-rich rich-text notes app with local SQLite persistence, custom category filtering, dynamic themes, image attachment support, and a polished splash-to-dashboard user flow.

---

## 3. Core Tech Stack & Dependencies

* **Framework:** Flutter (Latest Stable)
* **State Management:** `flutter_riverpod` (v2.x+, using the modern Notifier / AsyncNotifier pattern)
* **Database:** `sqflite` (For local relational storage)
* **Routing:** `go_router` (For declarative screen navigation)
* **Rich Text Editing:** `flutter_quill` (For formatting, text highlights, and styling)
* **Media Picker:** `image_picker` (For embedding local images into the rich text editor)
* **Persistence:** `shared_preferences` (For storing first-launch onboarding status and user settings)
* <https://dribbble.com/shots/25640565-Mobile-Note-Taking-App> use this as refrence for th e ui

---

## 4. Directory & Folder Structure

Enforce this feature-first modular architecture inside `lib/`:

```text
lib/
├── core/
│   ├── constants/       # App-wide constants, spacing, and design tokens
│   ├── database/        # SQLite database helper, initialization, and tables
│   ├── router/          # GoRouter configuration (`/splash`, `/landing`, `/dashboard`, `/editor`)
│   └── theme/           # Light/Dark theme definitions and accent color schemes
├── features/
│   ├── onboarding/
│   │   └── presentation/ # SplashScreen and LandingScreen UI widgets
│   └── notes/
│       ├── data/        # SQLite database mappers and data repositories
│       ├── domain/      # Immutable domain models (Note, Category)
│       └── presentation/
│           ├── providers/ # Riverpod Notifiers & AsyncNotifiers for state & CRUD
│           ├── screens/   # NotesHomeDashboard and NoteEditorScreen
│           └── widgets/   # Category filter pills, note cards, and custom toolbar
└── main.dart            # Application entry point wrapped in ProviderScope

