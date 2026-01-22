# Auto-Update System - Targets Away User App

## Overview
The **Targets Away** app automatically checks for and downloads data updates from Firebase when you launch it. This ensures you always have the latest shooting rules, events, firearms, and target zone data.

## How It Works for Users

### Automatic Updates on Launch
1. **Open the App**: When you launch Targets Away, it automatically checks Firebase for new data
2. **Update Notification**: If new data is available, you'll see a dialog with:
   - Clear message: "New Data Available"
   - Description of what will be updated
   - Two options: "Update Now" or "Later"

### Downloading Updates
If you choose **"Update Now"**:
1. Shows a loading indicator with "Downloading update..." message
2. Downloads all new data from Firebase:
   - Event rules and competition data
   - Firearms database
   - Target zone scoring information
3. **Replaces** your existing event/firearm/target data
4. Shows success dialog with counts (e.g., "43 events, 15 firearms, 50 targets")

### Your Data is Safe
**What Gets Updated (Replaced):**
- ✅ Events (shooting competitions and rules)
- ✅ Firearms (firearm database)
- ✅ Target Info (target zone scoring data)

**What Stays Untouched:**
- ✅ Your personal scores and history
- ✅ Your firearm entries
- ✅ Your membership cards
- ✅ Your appointments
- ✅ All your personal data and settings

## Skipping Updates

If you choose **"Later"**:
- The app will work normally with your current data
- You'll be prompted again the next time you launch the app
- Your personal data is never affected

## When Updates Happen

Updates are created when the administrator:
1. Makes changes to events, firearms, or target zone data
2. Clicks "Sync to Firebase" in the admin app
3. This increments the version number on Firebase
4. Your app detects this version change on next launch

## Technical Details

### Version Tracking
- Firebase stores a version number in: `metadata/data_version`
- Your app stores the local version in Hive: `app_metadata` box
- Simple integer comparison (local vs remote)

### Data Storage
The app uses two types of local storage:
1. **Firebase-synced data** (gets updated):
   - Events box
   - Firearms_hive box
   - Target_info box

2. **Local-only data** (never touched):
   - Scores box
   - Personal firearms box
   - Membership cards box
   - Appointments box

## Troubleshooting

### "Update Failed" Message
If you see this error:
- Check your internet connection
- Try again later
- The app will work with your current data

### Update Not Appearing
If you know there's an update but don't see it:
- Close and reopen the app
- Check your internet connection
- The version check happens in the first few seconds after launch

## Privacy & Data

- Updates only download public event/firearm/target data
- Your personal scores and data are stored locally only
- No personal data is uploaded to Firebase
- Updates happen over HTTPS (secure connection)

## Files Involved

- `lib/services/data_sync_service.dart` - Version checking
- `lib/utils/import_data.dart` - Data downloading
- `lib/screens/home_screen.dart` - Update prompts
