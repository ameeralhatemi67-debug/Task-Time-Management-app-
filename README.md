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

# 📝 Task Master: University Productivity Suite

Task Master is a Flutter-based productivity application designed specifically for university students. It integrates task management, habit tracking, and focus sessions with a "Privacy First" architecture that allows full functionality without requiring an immediate cloud account.

---

## 🛠️ Getting Started

### 1. Prerequisites
Ensure you have the Flutter environment set up (refer to the **Main Technical Report** for full environment installation steps).

### 2. Firebase Configuration
To enable Google Authentication:
1.  Place your `google-services.json` file in the `android/app/` directory.
2.  *Note:* If this file is missing, the app will automatically launch in **Offline/Guest Mode**.

### 3. Execution Commands
Open your terminal in the project root and use the following "Command Palette":

**First Time Setup:**
bash
flutter pub get

### Run the App:
flutter run

### Clean Reset (Run this if you see UI glitches):
flutter clean
flutter pub get

---

### 🛡️ The Architect's Guarantee
This `README.md` accurately reflects the state of your project as of our latest edits today. It correctly documents the "Guest Mode" logic and the "Tasks Page" default routing that we just finalized.

### 🎯 Your Next Step
1. **Save** the `README.md` file.
2. **Commit and Push** one last time to GitHub to make sure your documentation is live:
   ```bash
   git add README.md
   git commit -m "docs: update README with Guest Mode and project execution guide"
   git push origin main








