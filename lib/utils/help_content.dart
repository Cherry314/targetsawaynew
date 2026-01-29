// lib/utils/help_content.dart

class HelpContent {
  static const String homeScreen = '''
Welcome to Targets Away!

This is your home screen featuring the app's branding and a scenic shooting range backdrop.

What you can do:
• Tap the menu icon (☰) in the top-left to access all features
• Navigate to Enter Score to log your shooting sessions
• View your History to see past targets
• Track Progress with detailed charts
• Manage your Personal armory and membership cards
• Schedule events in the Calendar
• Customize the app in Settings

Tip: Use the drawer menu to quickly navigate between screens!
''';

  static const String enterScoreScreen = '''
Enter Score Screen

This is where you record your shooting sessions.

How to use:
• Select the Date of your session, you can back-date if desired.
• Choose your Practice type (configure favorites via the settings icon to the side.)
• Select your firearm's Caliber and Firearm ID
• Once you have selected a practice and Firearm ID, you can see the Event Conditions by tapping the Event Conditions icon at the top right corner.
• You can enter your score, and any X's directly, or use the custom calculator by tapping the Icon at the top right of the Score & Detail section.
• Enter your Score (required)
• Optionally add Firearm details, Competition info, or Notes. If you record any extra details, It will highlight the item.
• Capture a Target photo if desired
• Tap "Save Entry" to store your session

Tips:
• Your last selections are remembered for quick entry next time.
• you can see all your entries in the History screen
• All saved entries automatically appear in your Calendar
''';

  static const String historyScreen = '''
Previous Targets Screen

View and manage all your shooting session history.

How to use:
• Use the filters at the top to narrow results by Practice, Caliber, or Firearm
• Scroll through your entries sorted by date (newest first)
• Tap any entry to view the full-size target image (if captured), and specific zone scores if you used the custom calculator.
• Swipe left on an entry to delete it
• Swipe right on an entry to edit it

Tips:
• Set filters to "All" to see everything
• Deleted entries are removed from both History and Calendar
• Target images can be zoomed by pinching when viewing
''';

  static const String progressScreen = '''
Progress Graph Screen

Visualize your shooting performance over time.

How to use:
• Use the filter dropdowns to select specific Practice, Caliber, or Firearm
• Tap the chart type button to switch between:
  - Straight Line (linear connections)
  - Curved Line (smooth bezier curves)
  - Bar Chart (vertical bars)
  - Stepped Line (stepped progression)
• Tap any point on the graph to see detailed information
• View statistics like average score, best score, and trend

Tips:
• Filter by specific practices to track individual skills
• Compare different firearms using the firearm filter
• Look for trends to identify areas for improvement
• More data points create more meaningful visualizations
''';

  static const String calendarScreen = '''
Calendar Screen

Manage shooting appointments and view logged sessions.

How to use:
• Tap any date to see appointments for that day
• Use the "Add" button to create new appointments
• Tap the target icon (bottom-left) to log a score for the selected day
• Tap the + button (bottom-right) to add a general appointment
• Tap "Today" to quickly return to the current date
• Score entries appear with a target icon 🎯
• Regular appointments show the time

Tips:
• Score entries created here link to the calendar automatically
• Dots on dates indicate scheduled items
• Swipe or pinch the calendar to navigate months
• Appointments can include notifications (1 day or 1 week before)
''';

  static const String personalScreen = '''
Personal Screen

Manage your firearms collection and membership cards.

Two tabs available:

ARMORY TAB:
• Add firearms with details: Nickname, Make, Model, Caliber, Scope
• Mark firearms as "Owned" or just wish list items
• Capture photos of each firearm
• Add notes for maintenance or specifications
• Tap any firearm to view full details
• Edit or delete firearms as needed

MEMBERSHIP CARDS TAB:
• Store membership cards digitally
• Add Member Name and capture front/back photos
• Quick access to your range or club memberships
• Tap any card to view full-screen images
• Swipe through front and back with ease

Tip: Keep your armory updated to easily track which firearms you use most!
''';

  static const String settingsScreen = '''
Settings Screen

Customize Targets Away to your preferences.

Available settings:

THEME:
• Choose from 6 color themes
• Options: Default (Blue), Purple, Green, Orange, Red, Teal
• Theme applies throughout the app instantly

ANIMATIONS:
• Toggle home screen animations on/off
• Disable for better battery life or personal preference

IMAGE QUALITY:
• Adjust camera image quality (Low 50%, Medium 70%, Large 85%)
• Lower quality saves storage space
• Higher quality provides better detail for target analysis

PRACTICE LIST:
• Manage your favorite practice types
• Star practices to show in Enter Score dropdown
• Unstarred practices are hidden but data is preserved

BACKUP & RESTORE:
• Export all data to a backup file
• Restore from previous backups
• Include/exclude images to manage file size
• Share backups via any app

STORAGE USAGE:
• View app data storage breakdown
• See space used by scores, images, and other data

Tip: Regular backups protect your valuable shooting data!
''';

  static const String armoryTab = '''
Armory Tab

Build and manage your firearms collection.

How to use:
• Tap the + button to add a new firearm
• Fill in details:
  - Nickname (for easy identification)
  - Make and Model
  - Caliber
  - Scope Size (optional)
  - Notes (maintenance, modifications, etc.)
• Mark "Owned" checkbox for firearms you own
• Capture a photo of the firearm
• View all firearms in a scrollable list
• Tap any card to see full-screen details
• Edit or delete via the dialog options

Tips:
• Use nicknames like "Competition .22" or "Hunting Rifle"
• Track firearms you're interested in (uncheck "Owned")
• Add maintenance schedules in notes
• Photos help with identification and insurance records
''';

  static const String membershipCardsTab = '''
Membership Cards Tab

Store your shooting club and range memberships digitally.

How to use:
• Tap the + button to add a new card
• Enter the Member Name
• Capture the front of the card
• Capture the back of the card
• Save the card for quick access
• Tap any card to view full-screen
• Swipe left/right to see front and back
• Edit or delete cards as needed

Tips:
• Keep cards handy without carrying physical copies
• Useful for range check-ins
• Store multiple club memberships
• Update when cards are renewed
• Photos should be clear and well-lit for scanning
''';
}
