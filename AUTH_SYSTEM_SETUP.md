# Authentication System Setup Guide

## ✅ What's Been Created

### 1. User Model
**File:** `lib/models/user_profile.dart`
- Stores user information (firstName, lastName, email, clubs, timestamps)
- Supports multiple club memberships
- JSON serialization for Firestore

### 2. Authentication Service
**File:** `lib/services/auth_service.dart`
- **Registration:** Email/password with profile creation
- **Login:** Email/password authentication  
- **User Management:** Get/update profiles, delete account, re-authentication
- **Passcode:** Set/verify/clear 4-6 digit passcode (stored securely)
- **Biometric:** Check availability, enable/disable, authenticate with fingerprint/Face ID
- **Club Options:** 5 predefined clubs (can select multiple)

### 3. Registration Screen
**File:** `lib/screens/auth/registration_screen.dart`
- First name, last name, email input
- Password with confirmation
- Multiple club selection (checkboxes)
- Form validation
- Navigates to security setup after registration

### 4. Login Screen
**File:** `lib/screens/auth/login_screen.dart`
- Email and password fields
- Toggle password visibility
- Navigates to app unlock or security setup based on user's settings

### 5. Packages Added
```yaml
local_auth: ^2.3.0                    # Biometric authentication
flutter_secure_storage: ^9.2.2        # Secure passcode storage
```

## 🚧 What Still Needs to be Created

### Priority 1: Complete Authentication Flow

1. **Security Setup Screen** (`lib/screens/auth/security_setup_screen.dart`)
   - Let user choose: Passcode, Biometric, or Skip
   - Setup passcode (4-6 digits with confirmation)
   - Enable biometric if available
   - Navigate to home after setup

2. **App Unlock Screen** (`lib/screens/auth/app_unlock_screen.dart`)
   - Show passcode input OR biometric prompt
   - Unlock and navigate to home on success
   - Option to logout

3. **Update Settings Screen** (add to existing `lib/screens/settings_screen.dart`)
   - Add "Account" section with:
     - User name display
     - Change clubs
     - Logout button
     - Delete account button (with confirmation)
   - Add "Security" section with:
     - Change passcode
     - Enable/disable biometric
     - Re-authenticate for sensitive operations

4. **Update Main.dart** (`lib/main.dart`)
   - Add auth state listener
   - Add new routes:
     - `/login`
     - `/register`
     - `/security_setup`
     - `/app_unlock`
   - Set initial route based on auth state
   - Wrap app with auth check

### Priority 2: Platform Configuration

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<!-- Add biometric permission -->
<uses-permission android:name="android.permission.USE_BIOMETRIC"/>
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<!-- Add Face ID usage description -->
<key>NSFaceIDUsageDescription</key>
<string>We need Face ID to secure your app</string>
```

## 📋 Implementation Checklist

- [x] User model created
- [x] Auth service created
- [x] Registration screen created
- [x] Login screen created
- [x] Packages installed
- [ ] Security setup screen
- [ ] App unlock screen
- [ ] Update settings screen
- [ ] Update main.dart routes and auth state
- [ ] Add platform permissions (Android/iOS)
- [ ] Test registration flow
- [ ] Test login flow
- [ ] Test passcode
- [ ] Test biometric
- [ ] Test logout
- [ ] Test delete account

## 🎯 Quick Integration Steps

### Step 1: Add Routes to main.dart
```dart
routes: {
  '/login': (context) => const LoginScreen(),
  '/register': (context) => const RegistrationScreen(),
  '/security_setup': (context) => const SecuritySetupScreen(),
  '/app_unlock': (context) => const AppUnlockScreen(),
  // ... existing routes
}
```

### Step 2: Add Auth State Check
```dart
// In MyApp build method
home: StreamBuilder<User?>(
  stream: AuthService().authStateChanges,
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const SplashScreen();
    }
    if (snapshot.hasData) {
      return const AppUnlockScreen(); // or HomeScreen
    }
    return const LoginScreen();
  },
),
```

### Step 3: Update Settings Screen
Add logout and delete account buttons in a new "Account" section.

## 🔐 Security Features

1. **Passcode**
   - Stored in secure storage (encrypted)
   - Per-user (supports multiple accounts)
   - Can be 4-6 digits

2. **Biometric**
   - Works on both Android (fingerprint) and iOS (Face ID/Touch ID)
   - Falls back to passcode if biometric fails
   - User can enable/disable anytime

3. **Account Deletion**
   - Requires recent authentication
   - Deletes Firestore data
   - Deletes Firebase Auth user
   - Clears local passcode

## 🏆 Available Clubs

1. Springfield Rifle Club
2. Oak Valley Shooting Range  
3. Mountain View Gun Club
4. Riverside Marksmanship Association
5. Metro Target Sports

Users can select multiple clubs during registration.

## 📊 Firestore Structure

```
users/
  {userId}/
    - uid: string
    - email: string
    - firstName: string
    - lastName: string
    - clubs: array of strings
    - createdAt: timestamp
    - lastLoginAt: timestamp
```

## 🚀 Next Steps

1. Let me know if you want me to create the remaining screens (Security Setup and App Unlock)
2. I can also update your Settings screen with logout/delete functionality
3. Then we'll integrate everything into main.dart
4. Finally, add the platform-specific permissions

Would you like me to continue creating the remaining screens now?
