# task_manager_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## 🚀 Quick Start (For Developers)

This app is built with an **Offline-First** architecture, meaning it can run completely locally without an internet connection or a backend server!

### Option 1: Guest Mode (Offline - Recommended for testing)
Simply clone the repository and run the app. All tasks and habits will be saved locally to your device using Hive.
*(Note: Google Sign-In and Cloud Backup will be disabled in this mode).*

### Option 2: Cloud Sync Mode (Authenticated)
If you wish to enable Google Sign-In and Cloud Backups:
1. Create a project in the [Firebase Console](https://console.firebase.google.com/).
2. Register your Android app and download the `google-services.json` file.
3. Place the file inside the `android/app/` directory.
4. Run the app.