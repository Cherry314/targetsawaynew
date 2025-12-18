# Calendar & Score Integration Guide

This document describes the integrated calendar and scoring system in the Targets Away app.

## Overview

The calendar and scoring systems are now fully integrated, allowing you to:

- **Automatically create calendar entries** when you record a score
- **View score details** directly from the calendar
- **Enter scores with pre-filled dates** from the calendar screen

## Features

### 1. Automatic Calendar Entries for Scores

When you save a score entry, the app automatically creates a calendar appointment with:

- **Title**: "Score of XXX Recorded" (where XXX is your score)
- **Description**: Practice type, caliber, and firearm information
- **Date/Time**: Same as the score entry date
- **Visual Indicator**: Green target icon in the calendar

#### How it Works:

1. Go to **Enter Score** screen
2. Fill in your score details (score, practice, caliber, firearm, etc.)
3. Capture target image (optional)
4. Save the entry
5. **A calendar appointment is automatically created!**

### 2. View Score Details from Calendar

Calendar appointments linked to scores display:

- **Green target icon** instead of time (easy to identify)
- Score, practice, caliber, and firearm details
- Full target image with zoom/pan capabilities

#### How to View:

1. Open the **Calendar** screen
2. Select a date with score entries (look for the green dot)
3. **Tap the score entry** (with green target icon)
4. View the complete score details and target image

### 3. Enter Score with Pre-filled Date

You can quickly enter a score for a specific calendar date:

#### How to Use:

1. Open the **Calendar** screen
2. **Select the date** you want to record a score for
3. Tap the **target icon button** (🎯) in the top-right corner
4. The Enter Score screen opens with the **date pre-filled**
5. Enter your score details and save

**Location**: The target icon button is next to the "Add" button in the selected day header.

## Visual Indicators

### In the Calendar View:

- **Green dot under date**: Indicates day has score entries or appointments
- **Regular dot color**: Standard appointments only

### In the Appointments List:

- **Green target icon (🎯)**: Score entry - tap to view score details
- **Time display**: Regular appointment - tap to edit

## Automatic Synchronization

### When Scores are Updated:

- **Edit a score**: Calendar entry automatically updates
- **Delete a score**: Calendar entry automatically removed
- Changes happen in real-time, no manual sync needed

### When Calendar Entries are Managed:

- **Score-linked entries**: Cannot be edited or deleted through appointment dialog
- **Must edit/delete the score**: Use History screen or Enter Score screen
- **Regular appointments**: Can be edited/deleted normally

## Quick Reference

| Action | How To |
|--------|--------|
| **View all scores for a date** | Calendar → Select date → See green target icons |
| **View score details** | Calendar → Tap score entry (green icon) |
| **Enter score for specific date** | Calendar → Select date → Tap target icon button |
| **Edit score** | History → Swipe right on score OR Calendar → Tap score → (redirects to History) |
| **Delete score** | History → Swipe left on score |

## Technical Details

### Data Models

**AppointmentEntry** now includes:

```dart
String? linkedScoreId;     // Links to ScoreEntry.id
bool isScoreEntry;         // Identifies score-generated appointments
```

### Services

**CalendarScoreService** handles:

- Creating calendar entries when scores are saved
- Updating calendar entries when scores are edited
- Deleting calendar entries when scores are deleted
- Retrieving linked score data from appointments

### File Structure

New/Modified Files:

- `lib/services/calendar_score_service.dart` - Integration service
- `lib/models/appointment_entry.dart` - Added score linking fields
- `lib/screens/calendar_screen.dart` - Added score viewing and entry
- `lib/screens/enter_score_screen.dart` - Auto-creates calendar entries
- `lib/screens/history_screen.dart` - Deletes linked calendar entries

## Best Practices

### For Users:

1. **Don't delete score calendar entries** - They're managed automatically
2. **Use History screen** to manage scores
3. **Use target icon button** for quick score entry on specific dates

### For Developers:

1. **Score-linked appointments** should only be created/modified via `CalendarScoreService`
2. **Always check** `isScoreEntry` before allowing manual edits
3. **Maintain sync** by calling service methods when scores change

## Troubleshooting

### Score entry not appearing in calendar

- Ensure the score was saved successfully
- Check that the date matches
- Try refreshing the calendar (navigate away and back)

### Can't edit score-linked appointment

- This is by design - edit the score in History screen instead
- Score changes will automatically update the calendar entry

### Duplicate entries showing

- Each score creates one calendar entry
- If you see duplicates, check History screen for duplicate scores

## Future Enhancements

Potential improvements:

- Batch view of all scores for a week/month
- Statistics dashboard from calendar view
- Filter calendar to show only scores or only appointments
- Export calendar entries to external calendar apps
