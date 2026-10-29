# 🍎🤖 Native Platform Deep Knowledge (iOS & Android)

> Platform-specific configurations, permissions, build troubleshooting, and cross-platform guard rules.

---

## 1. iOS Deep Knowledge

### Workspace & Project Setup
- **Always open `Runner.xcworkspace`** when using Xcode — never `Runner.xcodeproj` (CocoaPods dependencies require the workspace).
- Minimum iOS deployment target: iOS 13.0+. Ensure `platform :ios, '13.0'` is specified at the top of `ios/Podfile`.
- **Privacy Manifest (`PrivacyInfo.xcprivacy`)**: Required for iOS 17+ compliance. Ensure required reason APIs (file timestamps, system boot time, disk space, user defaults) are declared.

### iOS Permissions (`ios/Runner/Info.plist`)
Every requested permission must have an explicit human-readable usage string defined in `Info.plist`:

| Permission Domain | Key in `Info.plist` | Example String Value |
|-------------------|---------------------|----------------------|
| Camera | `NSCameraUsageDescription` | "We need camera access to capture your profile photo." |
| Photo Library | `NSPhotoLibraryUsageDescription` | "We need photo library access to upload profile pictures." |
| Microphone | `NSMicrophoneUsageDescription` | "We need microphone access for recording voice notes." |
| Location (In Use) | `NSLocationWhenInUseUsageDescription` | "We need location access to find nearby matches." |
| Push Notifications | `UIBackgroundModes` (`remote-notification`) | Enable background notification processing |

### Apple Push Notification Service (APNs) & Signing
- **Provisioning Profiles**: Ensure Push Notification capability is added in Apple Developer Portal and enabled in Xcode (`Signing & Capabilities`).
- **APNs Key**: Provide `.p8` key in Firebase Console under iOS Project Settings.
- **Fastlane Match**: Recommended for managing development and distribution certificates across team members.

### Common iOS Issues & Solutions

| Error / Issue | Root Cause | Solution |
|---------------|------------|----------|
| CocoaPods pod spec error | Stale lockfile or pod cache | `cd ios && pod deintegrate && pod install` |
| Xcode 15+ script sandbox error | `ENABLE_USER_SCRIPT_SANDBOXING` enabled | Set `ENABLE_USER_SCRIPT_SANDBOXING = NO` in Build Settings |
| Simulator compilation error (`arm64`) | M-series Mac architecture collision | Exclude `arm64` architecture for Simulator in Xcode Build Settings |
| App Store Privacy Rejection | Missing usage string or Privacy Manifest | Audit `Info.plist` strings and `PrivacyInfo.xcprivacy` |

---

## 2. Android Deep Knowledge

### SDK Configurations (`android/app/build.gradle`)
- `minSdkVersion`: 21 (Android 5.0 Lollipop minimum)
- `targetSdkVersion`: 34 or 35 (Must comply with Google Play annual SDK update policy)
- `compileSdkVersion`: 34 or 35
- **AGP Namespace**: Ensure `namespace 'com.yourcompany.yourapp'` is defined in `android/app/build.gradle` (required by AGP 7+ / 8+).

### Android Permissions (`android/app/src/main/AndroidManifest.xml`)

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Internet Access -->
    <uses-permission android:name="android.permission.INTERNET" />
    
    <!-- Camera -->
    <uses-permission android:name="android.permission.CAMERA" />
    
    <!-- Storage (Android 12 & below) -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
    
    <!-- Granular Media Storage (Android 13+ / API 33+) -->
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
    <uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
    
    <!-- Notifications (Android 13+ / API 33+) -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
</manifest>
```

### ProGuard / R8 Rules (`android/app/proguard-rules.pro`)
When building release APKs/AABs (`--obfuscate`), preserve models and serialization classes:

```proguard
# Keep model data classes for JSON serialization
-keep class com.yourcompany.yourapp.models.** { *; }

# Stacked / GetIt reflection preservation
-keep class com.yourcompany.yourapp.app.** { *; }

# Retrofit / Gson / Freezed preservation
-keepattributes Signature, InnerClasses, EnclosingMethod
-keepclassmembers enum * { public static **[] values(); public static ** valueOf(java.lang.String); }
```

### Common Android Issues & Solutions

| Error / Issue | Root Cause | Solution |
|---------------|------------|----------|
| `64k method limit exceeded` | Too many dependencies | Add `multiDexEnabled true` in `defaultConfig` |
| Android 12 Activity launch error | Missing `android:exported` | Explicitly specify `android:exported="true"` (or `false`) on all `<activity>` tags |
| FileProvider collision | Duplicate authority string | Set authority to `${applicationId}.fileprovider` |
| Release build crash (Missing Class) | R8 shrinking over-aggressive | Add `-keep` rules in `proguard-rules.pro` |

---

## 3. Cross-Platform Guard Rules

Use the proper platform check depending on context:

```dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

// Service / Logic level check (Dart runtime)
if (Platform.isIOS) {
  // Execute iOS specific service logic
} else if (Platform.isAndroid) {
  // Execute Android specific service logic
}

// UI / Widget level check (Flutter target platform)
if (defaultTargetPlatform == TargetPlatform.iOS) {
  // Render iOS Cupertino style widget
}

// Web guard
if (kIsWeb) {
  // Handle web platform difference
}
```

> ⚠️ **Testing Rule**: Never assume emulator/simulator behavior accurately mirrors physical hardware. Test push notifications, camera, biometric auth, and secure storage on **real physical iOS and Android devices** prior to release.
