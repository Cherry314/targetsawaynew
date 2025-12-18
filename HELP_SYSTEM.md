# Help System Documentation

## Overview

A comprehensive help system has been added to Targets Away. Every screen with an AppBar now features
a **help icon (?)** in the top-right corner that displays contextual help when tapped.

## Implementation

### New Files Created

1. **`lib/widgets/help_icon_button.dart`**
    - Reusable widget that displays a help icon button
    - Shows a dialog with screen-specific help content when tapped
    - Consistent design across all screens

2. **`lib/utils/help_content.dart`**
    - Centralized repository of all help text
    - Easy to edit and update help content
    - Contains detailed instructions for each screen

## Screens Updated

All main screens now have help icons:

### 1. **Home Screen**

- Help explains app navigation and features
- How to use the drawer menu

### 2. **Enter Score Screen**

- Step-by-step guide for logging shooting sessions
- Explains all fields and optional features
- Tips for efficient data entry

### 3. **History Screen (Previous Targets)**

- How to filter and view past entries
- Swipe gestures for edit/delete
- Image viewing capabilities

### 4. **Progress Graph Screen**

- Chart type explanations
- Filter usage guide
- How to interpret the visualizations

### 5. **Calendar Screen**

- Managing appointments
- Adding score entries via calendar
- Notification settings

### 6. **Personal Screen**

- Covers both Armory and Membership Cards tabs
- Adding/editing firearms
- Managing membership cards

### 7. **Settings Screen**

- All settings explained
- Theme customization
- Backup/restore procedures
- Storage management

## Help Content Topics

Each help dialog includes:

- **Purpose**: What the screen is for
- **How to use**: Step-by-step instructions
- **Tips**: Best practices and helpful hints
- **Features**: Key capabilities highlighted

## Usage

Users simply tap the **?** icon in the top-right corner of any screen to access contextual help. The
help dialog can be dismissed by tapping "Got it!" or tapping outside the dialog.

## Customization

To edit help content:

1. Open `lib/utils/help_content.dart`
2. Find the relevant screen's constant (e.g., `enterScoreScreen`)
3. Edit the text as needed
4. No code changes required elsewhere - it updates automatically

## Design

- **Icon**: Question mark outline (`Icons.help_outline`)
- **Color**: Inherits from theme (white on most screens)
- **Position**: Right side of AppBar actions
- **Dialog**: Clean, scrollable design with icon header
- **Button**: "Got it!" for easy dismissal

## Benefits

- **New User Onboarding**: Helps users understand features immediately
- **Context-Sensitive**: Each screen has relevant information
- **Non-Intrusive**: Available when needed, hidden otherwise
- **Easy Maintenance**: Centralized content is simple to update
- **Consistent UX**: Same pattern across entire app
