# 🚀 Infinity Notes

[![Version](https://img.shields.io/badge/version-1.0.4-blue)](https://github.com/HimanshuV31/infinity-notes)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Enabled-FFCA28?logo=firebase)](https://firebase.google.com)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Google Play](https://img.shields.io/badge/Google%20Play-Open%20Testing-34A853?logo=google-play)](https://play.google.com/store/apps)

**A production-grade, cross-platform notes app with AI-powered summarization, real-time cloud sync, and adaptive theming.**

Developed by **Himanshu Vaishnav** | [LinkedIn](https://linkedin.com/in/himanshuv31) | [GitHub](https://github.com/HimanshuV31)

---

## ✨ Features

### 🎨 **Modern UI/UX**
- **Adaptive Themes**: Light, Dark, and System modes with Material Design 3
- **Multiple View Modes**: List, Grid, and Masonry layouts for flexible note browsing
- **Custom Sliver AppBar**: Animated search bar with smooth scrolling transitions
- **Clickable Links**: Automatic URL detection with in-app link cards

### 🤖 **AI-Powered Intelligence**
- **Smart Summarization**: Gemini 2.5 Flash AI generates concise summaries of long notes
- **Retry Logic**: Automatic fallback and error recovery for AI operations
- **Input Validation**: Optimized prompts for 1000-1200 token comprehensive summaries
- **Save as Note**: Transform AI summaries into new notes with one tap

### ☁️ **Cloud & Sync**
- **Real-Time Firestore Sync**: Changes propagate across devices in <5 seconds
- **Offline-First**: Create, edit, delete notes without internet; syncs when online
- **Multi-Device Support**: Seamless experience across phones and tablets
- **Data Persistence**: Local storage with SharedPreferences and Firestore

### 🔐 **Secure Authentication**
- **Google Sign-In**: One-tap OAuth authentication
- **Apple Sign-In**: Native iOS authentication (iOS only)
- **Email/Password**: Traditional auth with email verification
- **BLoC State Management**: Event-driven, reactive authentication flow

### 🔍 **Advanced Search**
- **Real-Time Search**: Instant results as you type with debounced input
- **Full-Text Indexing**: Searches note titles and content simultaneously
- **Sub-50ms Latency**: Optimized search for 10K+ notes at 60fps scrolling
- **Empty State Handling**: Graceful UI when no results found

### ⚙️ **Settings & Customization**
- **Theme Switcher**: Toggle between Light, Dark, and System themes
- **Bug Reporting**: Integrated EmailJS feedback system with device diagnostics
- **App Version Display**: Real-time version tracking with What's New dialog
- **Persistent Preferences**: Theme and view mode selection saved locally

---

## 🏗️ Architecture

Infinity Notes follows **Clean Architecture** principles with clear separation of concerns:

### **Project Structure**

**Core Directories:**

- **`ai_summarize/`** - Gemini AI integration with Singleton pattern
- **`constants/`** - Routes, API keys, and app-wide constants
- **`helpers/`** - Loading screens and utility functions
- **`services/`** - Business logic and external integrations
    - **`auth/`** - Authentication layer
        - `bloc/` - BLoC pattern (Events, States, AuthBloc)
        - `auth_service.dart` - Service orchestration layer
        - `auth_provider.dart` - Interface contract
        - `firebase_auth_provider.dart` - Firebase adapter implementation
    - **`cloud/`** - Firestore CRUD operations
    - **`search/`** - Search BLoC with debounced input
    - **`theme/`** - ThemeNotifier with SharedPreferences persistence
    - **`feedback/`** - EmailJS integration for bug reports
- **`utilities/`** - Cross-cutting concerns
    - `generics/ui/` - Reusable custom widgets (SearchBar, ProfileDrawer, etc.)
- **`views/`** - Feature-specific UI screens (Login, Notes, Settings)

**Key Files:**
- `main.dart` - App entry point with BLoC and Provider setup
- `constants/routes.dart` - Named route definitions
- `constants/api_keys.dart` - API key management (gitignored)


### 🎯 **Design Patterns**
- **BLoC Pattern**: Event-driven state management for auth and search
- **Repository Pattern**: Data source abstraction (Firebase, Local Storage)
- **Singleton**: Global AI service and EmailJS feedback
- **Factory Pattern**: Exception handling with custom error types
- **Observer Pattern**: Real-time Firestore streams

---

## 🛠️ Tech Stack

| Category             | Technologies                                    |
|----------------------|-------------------------------------------------|
| **Framework**        | Flutter 3.x, Dart 3.x                           |
| **State Management** | BLoC 8.x, Provider 6.x                          |
| **Backend**          | Firebase Auth, Firestore, Firebase Storage      |
| **AI Integration**   | Google Gemini 2.5 Flash API                     |
| **Local Storage**    | SharedPreferences, SQLite (via Firestore cache) |
| **Networking**       | HTTP package for REST API calls                 |
| **UI Components**    | Material Design 3, Custom Slivers, Animations   |
| **Feedback**         | EmailJS for bug reports and user feedback       |
| **Version Control**  | Git, GitHub                                     |

---

## 📦 Installation & Setup

### **Prerequisites**
- Flutter SDK 3.0+ ([Install Flutter](https://docs.flutter.dev/get-started/install))
- Firebase Project ([Firebase Console](https://console.firebase.google.com))
- Gemini API Key ([Google AI Studio](https://aistudio.google.com/app/apikey))

### **Local Development Setup**

1. **Install Flutter dependencies**
   flutter pub get

2. **Firebase Configuration**
- Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
- Add Android/iOS apps and download `google-services.json` (Android) / `GoogleService-Info.plist` (iOS)
- Place files in `android/app/` and `ios/Runner/` respectively
- Enable **Email/Password**, **Google Sign-In**, and **Apple Sign-In** in Firebase Authentication
- Create a **Firestore Database** with default security rules

1. **API Keys Configuration**
- Create `lib/[DIRECTORIES...]/api_keys.dart`:
  ```
  String GeminiAPIKey() => 'YOUR_GEMINI_API_KEY_HERE';
  ```
- **Important**: Add `api_keys.dart` to `.gitignore` to prevent accidental commits

1. **Build and Run**
   Debug mode
   flutter run

Release mode (production build)
flutter run --release

Build APK
flutter build apk --release

Build App Bundle (for Play Store)
flutter build appbundle --release


### **Download from Google Play** (Recommended)
- **Current Version**: 1.0.5 (Build 7)
- **Status**: Open Testing
- **Join Beta**: [Opt-in URL](https://play.google.com/store/apps/details?id=com.ehv.infinitynotes)

*Production release coming soon to Google Play Store.*

---

