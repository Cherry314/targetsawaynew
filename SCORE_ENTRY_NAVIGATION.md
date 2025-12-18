# Score Entry Navigation & Form Reset

This document describes the enhanced navigation and form reset behavior for the Enter Score screen.

## Overview

The Enter Score screen now intelligently handles navigation and form state based on how it was
accessed:

### Two Entry Paths

**1. From Calendar Screen (via 🎯 target icon)**

- Opens with selected date pre-filled
- After saving: Returns to calendar screen
- Use case: Recording scores for specific past/future dates

**2. From Menu/Drawer Navigation**

- Opens normally with today's date
- After saving: Form clears, ready for next entry
- Use case: Batch entry of multiple scores

## How It Works

### From Calendar Screen

**User Flow:**

1. Open Calendar screen
2. Select a date (e.g., yesterday or a specific past date)
3. Tap the 🎯 target icon button (top-right)
4. Enter Score screen opens with that date pre-filled
5. Fill in score, practice, caliber, etc.
6. Tap "Save Entry"
7. Confirm dialog: "Do you want to save this entry and return to the Calendar?"
8. After confirming: **Returns to Calendar screen**
9. See the new score entry immediately in the calendar

**Benefits:**

- Quick navigation back to calendar
- Immediate visual confirmation of saved entry
- Efficient for recording historical scores

### From Menu/Drawer

**User Flow:**

1. Open Enter Score from drawer menu
2. Fill in score details
3. Tap "Save Entry"
4. Confirm dialog: "Do you want to save this entry?"
5. After confirming:
    - **Form clears automatically**
    - Score field cleared
    - Optional fields (firearm name, notes, competition) cleared
    - Target image cleared
    - Date resets to today
    - Practice, caliber, and firearm ID kept (last used values)
    - Success message: "Score saved! Ready for next entry."
6. Cursor ready to enter next score

**Benefits:**

- Efficient batch entry workflow
- No need to navigate back to menu
- Quick consecutive entries
- Retains commonly reused selections

## Technical Implementation

### EnterScoreScreen Changes

**New Parameter:**

```dart
final bool openedFromCalendar;
```

**Default Behavior:**

- `openedFromCalendar = false` (when opened from menu)

**Conditional Navigation:**

```dart
if (widget.openedFromCalendar) {
  // Return to calendar
  Navigator.of(context).pushNamedAndRemoveUntil('/calendar', (route) => false);
} else {
  // Clear form for next entry
  _resetFormForNextEntry();
}
```

### Form Reset Logic

The `_resetFormForNextEntry()` method clears:

- ✅ Score field
- ✅ Firearm name
- ✅ Notes
- ✅ Competition ID and Result
- ✅ Target images
- ✅ Date (resets to today)

**Preserves:**

- ✅ Last used Practice
- ✅ Last used Caliber
- ✅ Last used Firearm ID

### Dialog Text Changes

**From Calendar:**
> "Do you want to save this entry and return to the Calendar?"

**From Menu:**
> "Do you want to save this entry?"

## User Benefits

### Workflow Efficiency

**Calendar Entry (Single Score):**

- 3 taps to record and see result
- No extra navigation steps
- Visual confirmation in calendar

**Menu Entry (Batch Scores):**

- Continuous entry without navigation
- Form intelligently clears
- Common selections preserved
- Perfect for entering multiple scores from a session

### Smart Defaults

The form reset keeps commonly reused values:

- If you're entering multiple scores from the same practice session
- Same caliber across multiple entries
- Same firearm ID for consecutive shots

Only clear fields that typically change between entries.

## Examples

### Scenario 1: Recording Yesterday's Score

```
Calendar → Select Yesterday → 🎯 → 
Enter score 95 → Save → Confirm →
Back to Calendar (showing new entry)
```

### Scenario 2: Entering Multiple Scores from Today's Session

```
Menu → Enter Score →
Score: 98 → Practice: Rapid Fire → Caliber: 9mm → Save → Confirm →
[Form clears, practice/caliber preserved] →
Score: 95 → [Practice/Caliber already selected] → Save → Confirm →
[Form clears again] →
Score: 97 → Save → Confirm →
Done!
```

## Code Changes

### Files Modified

**lib/screens/enter_score_screen.dart:**

- Added `openedFromCalendar` parameter
- Added `_resetFormForNextEntry()` method
- Modified save confirmation dialog text
- Conditional navigation after save

**lib/screens/calendar_screen.dart:**

- Updated `_openScoreEntryScreen()` to pass `openedFromCalendar: true`

### Testing Checklist

- [ ] Open from calendar → Save → Returns to calendar
- [ ] Open from menu → Save → Form clears
- [ ] Form reset preserves practice/caliber/firearm ID
- [ ] Form reset clears score, images, notes
- [ ] Success message shows after menu save
- [ ] Calendar shows new entry immediately

## Future Enhancements

Possible improvements:

- Option to configure which fields are preserved on reset
- Keyboard shortcut for quick save and next entry
- Batch import from CSV with this workflow
- "Save and New" vs "Save and Exit" buttons
