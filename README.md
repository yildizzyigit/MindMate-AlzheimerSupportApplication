# MindMate - Alzheimer Support Application

MindMate is a Flutter-based mobile application developed to support Alzheimer’s patients and their caregivers. The application provides a simple patient interface, caregiver management panel, medication tracking, mood tracking, memory games, and basic activity reports.

## Features

- Patient and caregiver role selection
- Caregiver registration and login with Firebase Authentication
- Patient management through the caregiver panel
- Medication schedule management
- Daily medication tracking
- Mood tracking for patients
- Memory-based cognitive games
- Weekly activity and medication reports
- Local photo/person management with SQLite
- Firebase Firestore integration for online data synchronization
- Android APK release

## Technologies Used

- Flutter
- Dart
- Firebase Authentication
- Cloud Firestore
- SQLite
- Provider state management
- SharedPreferences
- Image Picker
- Flutter Local Notifications

## Project Structure

```text
lib/
  main.dart
  providers/
    app_provider.dart
  services/
    firebase_service.dart
    notification_service.dart
  database/
    db_helper.dart
  screens/
    caregiver_screen.dart
    caregiver_patients_screen.dart
    patient_home_screen.dart
    medication_schedule_screen.dart
    weekly_report_screen.dart
    people_manager_screen.dart
    reminder_settings_screen.dart
```

## Main Modules

### Patient Panel

The patient panel is designed with a simple and visual interface. Patients can select their mood, view their daily medications, mark specific medications as taken, and access memory games.

### Caregiver Panel

The caregiver panel allows caregivers to manage patients, edit medication schedules, view mood information, track medication status, and check weekly reports.

### Firebase Integration

Firebase is used for caregiver authentication, patient data storage, medication schedules, medication logs, mood logs, and game scores.

### SQLite Usage

SQLite is used for local data storage, especially for person/photo records used in the face-name memory game. Firebase Storage is not used in this version.

## Firebase Configuration

Firebase configuration files are not included in this repository for security reasons.

The following files are ignored:

```text
lib/firebase_options.dart
android/app/google-services.json
ios/Runner/GoogleService-Info.plist
```

To run the project with Firebase, create your own Firebase project and configure it using FlutterFire CLI:

```bash
flutterfire configure
```

Then enable the required Firebase services:

- Firebase Authentication
- Cloud Firestore

## Installation

Clone the repository:

```bash
git clone https://github.com/yildizzyigit/MindMate-AlzheimerSupportApplication.git
cd MindMate-AlzheimerSupportApplication
```

Install dependencies:

```bash
flutter pub get
```

Run the application:

```bash
flutter run
```

Build APK:

```bash
flutter build apk --release
```

The release APK will be generated at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## Notes

This project was developed as an educational mobile application project. The main goal is to provide a supportive and easy-to-use digital tool for Alzheimer’s patients and caregivers.


## Screenshots

<p align="center">
  <img src="https://github.com/user-attachments/assets/99ad7ca4-4efa-4fd8-aead-d04aae4763ac" alt="Login Screen" width="220" />
  <img src="https://github.com/user-attachments/assets/d583efb2-1097-423e-846c-15c7474327d3" alt="Caregiver Panel" width="220" />
  <img src="https://github.com/user-attachments/assets/33cfbc7c-a2ab-40d3-aa87-35d6ad8908a6" alt="Patient Screen" width="220" />
  <img src="https://github.com/user-attachments/assets/71cbb45d-6ca1-46c6-a2a6-cfcf16057b58" alt="Games" width="220" />
</p>

## License

All rights reserved. This project is publicly available for viewing and educational review purposes only. Copying, modifying, distributing, or using the source code without permission is not allowed.

## Author

Developed by Yiğit Yıldız.
