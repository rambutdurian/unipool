# Firebase Cloud Messaging Setup Guide

## Overview
This document provides instructions for completing the Firebase Cloud Messaging setup for the UniPool Flutter application.

## What's Been Installed

### 1. Dependencies Added to pubspec.yaml
- `firebase_core: ^2.24.0` - Firebase core library
- `firebase_messaging: ^14.6.0` - Firebase Cloud Messaging
- `flutter_local_notifications: ^16.1.0` - Local notification display

### 2. Android Configuration
- Added Google Services plugin to `build.gradle.kts` files
- Added FCM permissions to `AndroidManifest.xml`
- Required permissions:
  - `INTERNET` - For network communication
  - `POST_NOTIFICATIONS` - For displaying notifications
  - `com.google.android.c2dm.permission.RECEIVE` - For receiving push messages
  - `WAKE_LOCK` - For acquiring wake locks

### 3. Firebase Messaging Service
Created `lib/services/firebase_messaging_service.dart` with:
- FCM token management
- Foreground message handling
- Background message handling
- Local notification display
- Topic subscription/unsubscription
- Permission request handling

### 4. Main App Initialization
Updated `lib/main.dart` to:
- Initialize Firebase on app startup
- Set background message handler
- Initialize Firebase Messaging service

## Next Steps

### Step 1: Set Up Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select existing one
3. Add an Android app to your project
   - Package name: `com.example.my_first_app` (or your custom package name)
   - App nickname: `unipool`
   - SHA-1 certificate fingerprint: (see below)

### Step 2: Get SHA-1 Certificate Fingerprint
Run this command in your project directory:
```bash
cd android
./gradlew signingReport
```

Look for "SHA1" under "debugAndroidTest" or "debug" variant.

### Step 3: Download google-services.json
1. From Firebase Console, download the `google-services.json` file
2. Place it in: `android/app/google-services.json`

### Step 4: Update Firebase Options
Edit `lib/firebase_options.dart` and replace the placeholder values:
- `YOUR_ANDROID_API_KEY` - From google-services.json
- `YOUR_ANDROID_APP_ID` - From google-services.json
- `YOUR_MESSAGING_SENDER_ID` - From google-services.json
- `YOUR_PROJECT_ID` - Your Firebase project ID
- `YOUR_STORAGE_BUCKET` - Your Firebase storage bucket

Example from google-services.json:
```json
{
  "project_info": {
    "project_id": "your-project-id",
    "project_number": "YOUR_MESSAGING_SENDER_ID"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "YOUR_ANDROID_APP_ID"
      },
      "api_key": [
        {
          "current_key": "YOUR_ANDROID_API_KEY"
        }
      ]
    }
  ]
}
```

### Step 5: Update Android Package Name (Optional)
If you want to change from `com.example.my_first_app`:
1. Edit `android/app/build.gradle.kts` - update `applicationId`
2. Edit `android/app/src/main/AndroidManifest.xml` if needed
3. Create new Firebase app in console with new package name

### Step 6: Run the App
```bash
flutter pub get
flutter run
```

## Testing FCM

### From Firebase Console:
1. Go to Cloud Messaging in Firebase Console
2. Click "Send your first message"
3. Enter title and body
4. Select "FCM Registration token"
5. Paste your device's FCM token (printed to console)
6. Send test message

### Getting FCM Token:
After app starts, check console for:
```
FCM Token: eXaMplEt0keNh3r3...
```

## Using the Firebase Messaging Service

### Subscribe to Topic:
```dart
await FirebaseMessagingService().subscribeToTopic('news');
```

### Unsubscribe from Topic:
```dart
await FirebaseMessagingService().unsubscribeFromTopic('news');
```

### Get FCM Token:
```dart
String? token = await FirebaseMessagingService().getFCMToken();
```

## Sending Messages from Backend

### Using Firebase Admin SDK (Node.js):
```javascript
const admin = require('firebase-admin');

// Send to specific device
await admin.messaging().send({
  notification: {
    title: 'Message Title',
    body: 'Message Body'
  },
  android: {
    priority: 'high'
  },
  token: 'DEVICE_FCM_TOKEN'
});

// Send to topic
await admin.messaging().send({
  notification: {
    title: 'Message Title',
    body: 'Message Body'
  },
  android: {
    priority: 'high'
  },
  topic: 'news'
});
```

## Handling Notifications

### Foreground Messages:
Handled automatically in `FirebaseMessagingService._showNotification()`

### Background Messages:
Handled in `_firebaseMessagingBackgroundHandler()` in main.dart

### Message Tap Handling:
Edit `_handleMessageTap()` in `firebase_messaging_service.dart` to add custom navigation or logic

## Important Notes

- **Android Manifest:** Ensure the FCM permissions are present before building
- **Firebase Credentials:** Keep `google-services.json` secure and add to `.gitignore`
- **Token Management:** Send FCM tokens to your backend for device tracking
- **Foreground Notifications:** Android 12+ requires notification permission request
- **Background Messages:** Can only have notification payload, not data-only payloads on Android

## Troubleshooting

### App Doesn't Receive Notifications:
1. Check that `google-services.json` is in correct location
2. Verify FCM token is correctly registered
3. Check Android logcat for permission errors
4. Ensure app is not in Doze mode

### Build Errors:
1. Run `flutter clean`
2. Run `flutter pub get`
3. Ensure gradle is properly installed

### Permissions Not Requested:
1. Check that `initializeFirebaseMessaging()` is called in main
2. For Android 13+, notification permission is required

## Additional Resources

- [Firebase Messaging Documentation](https://firebase.flutter.dev/docs/messaging/overview/)
- [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)
- [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup)
