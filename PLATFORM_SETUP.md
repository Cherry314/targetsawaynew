# Platform-Specific Configuration for Authentication

## 🤖 Android Configuration

### 1. Update AndroidManifest.xml

**File:** `android/app/src/main/AndroidManifest.xml`

Add these permissions inside the `<manifest>` tag (before `<application>`):

```xml
<!-- Biometric Authentication -->
<uses-permission android:name="android.permission.USE_BIOMETRIC"/>
<uses-permission android:name="android.permission.USE_FINGERPRINT"/>

<!-- Internet (already added by Firebase, but verify it's there) -->
<uses-permission android:name="android.permission.INTERNET"/>
```

### 2. Update build.gradle

**File:** `android/app/build.gradle`

Verify `minSdkVersion` is at least 23 (for biometric):

```gradle
android {
    defaultConfig {
        minSdkVersion 23  // Must be at least 23
        targetSdkVersion 34
    }
}
```

---

## 🍎 iOS Configuration

### 1. Update Info.plist

**File:** `ios/Runner/Info.plist`

Add these entries inside the `<dict>` tag:

```xml
<!-- Face ID Usage Description -->
<key>NSFaceIDUsageDescription</key>
<string>We use Face ID to securely authenticate you and protect your data</string>

<!-- Optional: Local Network (if you use any local features) -->
<key>NSLocalNetworkUsageDescription</key>
<string>Targets Away needs local network access for certain features</string>
```

### 2. Update Podfile (if needed)

**File:** `ios/Podfile`

Ensure platform version is at least 12.0:

```ruby
platform :ios, '12.0'
```

---

## 🔥 Firebase Configuration

### Firestore Security Rules

Update your Firestore security rules to protect user data:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User profiles - users can only read/write their own
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Add other collection rules as needed
  }
}
```

### Firebase Authentication Setup

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Authentication** → **Sign-in method**
4. Enable **Email/Password** provider
5. (Optional) Configure email templates for password reset

---

## 🧪 Testing Checklist

### Registration Flow
- [ ] Can register with all required fields
- [ ] Password validation works (min 6 chars)
- [ ] Email validation works
- [ ] Can select multiple clubs
- [ ] Redirects to security setup after registration

### Login Flow
- [ ] Can login with email/password
- [ ] Wrong password shows error
- [ ] Non-existent user shows error
- [ ] Redirects to app unlock after login

### Security Setup
- [ ] Can set up 4-6 digit passcode
- [ ] Passcode confirmation works
- [ ] Biometric option appears (if device supports it)
- [ ] Can skip security setup
- [ ] Settings save correctly

### App Unlock
- [ ] Passcode unlock works
- [ ] Biometric unlock works (if enabled)
- [ ] Wrong passcode shows error
- [ ] Can logout from unlock screen

### Settings
- [ ] User profile displays correctly
- [ ] Clubs display correctly
- [ ] Logout works
- [ ] Delete account works (with re-authentication)
- [ ] Can change passcode
- [ ] Can toggle biometric on/off

---

## 🚀 Quick Start Commands

```bash
# Install packages
flutter pub get

# For Android
flutter run

# For iOS (Mac only)
cd ios
pod install
cd ..
flutter run

# Clean build if issues
flutter clean
flutter pub get
flutter run
```

---

## 🐛 Common Issues & Solutions

### Issue: "USE_BIOMETRIC permission not found"
**Solution:** Make sure you've added the permission to AndroidManifest.xml and rebuilt the app.

### Issue: "Face ID not working on iOS"
**Solution:** 
1. Check Info.plist has NSFaceIDUsageDescription
2. Test on real device (not simulator)
3. Ensure Face ID is set up in device settings

### Issue: "Firebase auth not working"
**Solution:**
1. Verify firebase_core is initialized in main()
2. Check google-services.json (Android) or GoogleService-Info.plist (iOS) are in correct locations
3. Rebuild the app

### Issue: "Biometric prompt not showing"
**Solution:**
1. Ensure device has biometric set up
2. Check app permissions in device settings
3. Try on physical device (not all emulators support biometric)

### Issue: "Secure storage errors on Android"
**Solution:** Add this to android/app/build.gradle:
```gradle
android {
    packagingOptions {
        exclude 'META-INF/DEPENDENCIES'
    }
}
```

---

## 📱 Device Requirements

### Android
- Android 6.0 (API 23) or higher
- Fingerprint or face unlock set up for biometric

### iOS
- iOS 12.0 or higher
- Face ID or Touch ID set up for biometric

---

## 🔐 Security Best Practices

1. **Never store passwords in plain text** ✅ (Using Firebase Auth)
2. **Use secure storage for sensitive data** ✅ (Using flutter_secure_storage)
3. **Require re-authentication for sensitive operations** ✅ (Delete account)
4. **Implement proper Firestore security rules** ⚠️ (Configure in Firebase Console)
5. **Use HTTPS for all API calls** ✅ (Firebase handles this)

---

## 📚 Additional Resources

- [Firebase Auth Documentation](https://firebase.google.com/docs/auth)
- [Flutter Local Auth Package](https://pub.dev/packages/local_auth)
- [Flutter Secure Storage](https://pub.dev/packages/flutter_secure_storage)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)

---

## ✅ Completion Checklist

- [ ] Packages installed (`flutter pub get`)
- [ ] Android permissions added
- [ ] iOS Info.plist updated
- [ ] Firebase Authentication enabled
- [ ] Firestore security rules configured
- [ ] Tested on physical device
- [ ] Biometric working (if supported)
- [ ] Passcode working
- [ ] Logout working
- [ ] Delete account working

---

**Need Help?** Check the troubleshooting section or review the Firebase documentation.
