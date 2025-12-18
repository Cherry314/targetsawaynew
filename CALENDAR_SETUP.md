# Calendar Feature Setup Guide

This document provides setup instructions for the calendar and notification features in the Targets
Away app.

## Features Implemented

✅ Monthly calendar view with swipe/tap navigation
✅ Add, edit, and delete appointments
✅ Set appointment date and time
✅ Optional notifications (1 day and/or 1 week before)
✅ Cross-platform support (Android & iOS)
✅ Visual indicators for days with appointments
✅ List view of appointments for selected day

## Android Setup

The Android configuration has been completed automatically:

1. **AndroidManifest.xml** - Updated with notification permissions:
    - `POST_NOTIFICATIONS` - For Android 13+ notification permission
    - `SCHEDULE_EXACT_ALARM` - For scheduling exact time notifications
    - `USE_EXACT_ALARM` - For Android 14+ exact alarm permission
    - `RECEIVE_BOOT_COMPLETED` - To restore notifications after device reboot

2. **build.gradle.kts** - Enabled core library desugaring:
    - Required for flutter_local_notifications to work properly
    - Enables Java 8+ API compatibility

3. **No additional steps required** - The app will request notification permissions at runtime

## iOS Setup

For iOS, you need to update the `Info.plist` file:

### Location: `ios/Runner/Info.plist`

Add the following keys before the closing `</dict>` tag:

```xml
<!-- Notification permissions -->
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
    <string>processing</string>
</array>
```

## Usage Guide

### Adding an Appointment

1. Navigate to the Calendar screen from the drawer menu
2. Select a date by tapping on it
3. Tap the **"Add"** button or the floating action button (+)
4. Fill in the appointment details:
    - **Title** (required): Brief name for the appointment
    - **Description** (optional): Additional details
    - **Date**: Tap to change the selected date
    - **Time**: Tap to set the appointment time
    - **Notifications**: Check boxes for 1 day and/or 1 week reminders
5. Tap **"Create"** to save

### Editing an Appointment

1. Tap on any appointment in the list
2. Modify the details as needed
3. Tap **"Update"** to save changes
4. Or tap **"Delete"** to remove the appointment

### Navigating the Calendar

- **Swipe left/right** on the calendar to change months
- **Tap the arrows** in the header to change months
- **Tap the "Today" icon** in the app bar to jump to the current date
- **Days with appointments** show colored dots underneath

### Notifications

- Notifications are scheduled automatically when you save an appointment
- They will appear at the same time of day as your appointment, but 1 day or 1 week earlier
- If you edit or delete an appointment, the notifications are automatically updated or cancelled
- Notifications work even when the app is closed

## Technical Details

### Data Storage

- Appointments are stored locally using **Hive** database
- Data persists across app restarts
- No internet connection required

### Notification System

- Uses **flutter_local_notifications** plugin
- Supports both Android and iOS
- Timezone-aware scheduling with **timezone** package
- Automatically handles notification ID management

### Calendar UI

- Built with **table_calendar** package
- Responsive design that adapts to screen size
- Supports both light and dark themes
- Matches your app's color scheme

## Troubleshooting

### Notifications Not Working (Android 13+)

- The app will request notification permission on first use
- If denied, go to: Settings > Apps > Targets Away > Notifications > Enable

### Notifications Not Working (iOS)

- Ensure you've added the Info.plist entries
- Check: Settings > Targets Away > Notifications > Allow Notifications

### Exact Alarm Permission (Android 14+)

- Some devices may require special "Exact Alarm" permission
- Go to: Settings > Apps > Targets Away > Alarms & reminders > Allow

## Dependencies Added

```yaml
table_calendar: ^3.1.2            # Calendar UI widget
flutter_local_notifications: ^18.0.1  # Cross-platform notifications
timezone: ^0.9.4                  # Timezone support for scheduling
```

## Files Created/Modified

### New Files:

- `lib/models/appointment_entry.dart` - Appointment data model
- `lib/models/appointment_entry.g.dart` - Generated Hive adapter
- `lib/services/notification_service.dart` - Notification management
- `lib/widgets/appointment_dialog.dart` - Add/edit appointment dialog
- `lib/screens/calendar_screen.dart` - Main calendar screen (updated)

### Modified Files:

- `pubspec.yaml` - Added dependencies
- `lib/main.dart` - Initialize appointments box and notifications
- `android/app/src/main/AndroidManifest.xml` - Android permissions
- `android/app/build.gradle.kts` - Enabled core library desugaring
- `ios/Runner/Info.plist` - iOS background modes

## Future Enhancements (Optional)

Possible improvements you could add later:

- Recurring appointments (daily, weekly, monthly)
- Custom notification times (e.g., 2 hours before)
- Color coding for different appointment types
- Search/filter appointments
- Export appointments to calendar apps
- Sync across devices (would require backend)
