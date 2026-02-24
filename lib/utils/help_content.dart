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
• You can see the event if to tap the 'Show Event' button.
• If you have set up your own Firearms in your Personal page, you can select which Firearm used in the 'Select Firearm' Box. (this will automatically select the Caliber and FirearmID).
• Or you can select your firearm's Caliber and Firearm ID manually
• If you want to record a breakdown of your score, select the 'Score Calculator' Or you can enter a basic score / X by pressing the 'Basic Score' button.
• You can enter any notes for this particular event. 
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
• Set to Light Mode, Dark Mode, or use Device Settings

ANIMATIONS:
• Toggle home screen animations on/off
• Disable for better battery life or personal preference

IMAGE QUALITY:
• Adjust camera image quality (Low 50%, Medium 70%, Large 85%)
• Lower quality saves storage space
• Higher quality provides better detail for target analysis

ROUNDS COUNTER:
• Enable/disable rounds fired tracking
• View total rounds recorded
• Cannot retrieve historical data if turned off

BACKUP & RESTORE:
• Export all data to a backup file
• Restore from previous backups
• Include/exclude images to manage file size
• Share backups via any app

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

  static const String profileScreen = '''
Profile Screen

Manage your account information and security settings.

ACCOUNT INFORMATION:
• View your full profile including name, email, clubs, and member since date
• See which shooting clubs you are associated with

SECURITY:
• Change Passcode - Update your app unlock passcode
• Change Password - Update your account password (requires current password)
• Biometric Authentication - Enable/disable fingerprint/face unlock if available

ACCOUNT ACTIONS:
• Logout - Sign out of your account (you can log back in anytime)
• Delete Account - Permanently remove all your data and account

Tips:
• Keep your password secure and change it regularly
• Biometric authentication provides quick secure access
• Deleting your account is permanent and cannot be undone
• Ensure you have backups of any important data before deleting your account
''';

  static const String compPortal = '''
Competition Portal

Your central hub for all competition activity.

Three options available:

RUN A COMPETITION:
• Create and manage a live competition as the organiser
• Select the event, generate a QR code for participants to join
• Manage scores, close entries, and view the final results

JOIN A COMPETITION:
• Scan a QR code to join a competition being run by an organiser
• Submit your score and view live results as they come in
• See the final podium and full standings when the competition ends

COMPETITION HISTORY:
• View all your past competition results
• See your placement, score, and X count for each event
• Full podium and standings are stored for each competition

Tip: If you are running a competition, make sure you are in a location with internet access!
''';

  static const String eventSelectionScreen = '''
Event Selection Screen

Choose which event you want to run a competition for.

How to use:
• Browse the list of available events
• Tap an event to select it (it will be highlighted)
• Press "Start Competition" to proceed
• The competition will be created and a QR code generated for participants

Notes:
• Only events configured in your system will appear here
• Each competition is live for up to 3 hours before expiring
• Old abandoned competitions are cleaned up automatically

Tip: Make sure participants are ready before you start - the QR code appears on the next screen!
''';

  static const String competitionRunnerScreen = '''
Running Competition Screen

Manage your live competition as the organiser.

THE QR CODE:
• Share this QR code with all participants
• Participants scan it from their device to join
• Tap the copy icon to copy the Competition ID manually if needed

PARTICIPANT LIST:
• Shows all shooters who have joined (app users and manual entries)
• A tick icon shows when a shooter has submitted their score
• Progress is shown as "X of Y scores submitted"

ADDING MANUAL ENTRIES (Guests):
• Tap "Add Shooter" to add a guest who doesn't have the app
• Enter their name to add them to the competition
• You will enter their score manually after entries close

CLOSING ENTRIES:
• Tap "Close Entries" to stop new participants joining
• After closing, tap a guest entry to enter their score manually
• If you need to end early, tap "Close Competition Early"

ENDING THE COMPETITION:
• Once all scores are in, the button changes to "End Competition & Show Results"
• Tap it to calculate final standings and display the results
• Results are automatically sent to all app participants

Tip: You can close entries at any time - app users can still submit scores after entries close.
''';

  static const String competitionResultsScreen = '''
Competition Results Screen

View the final standings for the completed competition.

PODIUM:
• 1st, 2nd, and 3rd place are shown with gold, silver, and bronze styling
• Each entry shows the shooter's name, score, and X count

FULL STANDINGS:
• All other competitors are listed below the podium in order
• Each entry shows position, name, score, and X count

CLOSING THE COMPETITION:
• Tap "Close Competition" when you are done viewing results
• This will delete all competition data from the server
• You will be returned to the Competition Portal
• WARNING: This action cannot be undone

Note: All participant scores have already been saved to their own Competition History before you close.
''';

  static const String shooterScoreScreen = '''
Shooter Score Screen

Submit your score as a participant in a live competition.

WHILE THE COMPETITION IS OPEN:
• You can see the event name and your shooter name at the top
• Use the Score Calculator to calculate your score by entering hits per zone
• Or enter your score manually if the organiser allows it
• Tap "Submit Score" when you are ready

AFTER SUBMITTING:
• You will see a "Score Submitted" confirmation
• Wait for the organiser to end the competition

WHEN RESULTS ARE IN:
• The screen updates automatically when the organiser ends the competition
• You will see your final placement (1st, 2nd, 3rd, etc.)
• The full podium (top 3) is displayed with gold, silver, and bronze styling
• The Full Standings show all competitors in order below the podium
• Your result is automatically saved to your Competition History

Tips:
• Make sure you have a stable internet connection during the competition
• Do not close the app while waiting for results - it will update automatically
• Your score is saved to your history regardless of placement
''';

  static const String qrScannerScreen = '''
QR Scanner Screen

Scan the competition QR code to join a live competition.

How to use:
• Point your camera at the QR code displayed on the organiser's screen
• The code will be detected automatically - no button press needed
• Once scanned, you will see a confirmation screen with the competition details
• Enter your name and confirm to join

Tips:
• Make sure the QR code is clearly visible and well lit
• Hold your phone steady for a few seconds if it doesn't scan immediately
• If scanning fails, ask the organiser for the Competition ID and enter it manually
• You need an internet connection to join a competition
''';

  static const String joinConfirmationScreen = '''
Join Competition Screen

Confirm your details before joining the competition.

How to use:
• Check the event name shown matches the competition you want to join
• Enter your name as you want it to appear on the leaderboard
• Tap "Join Competition" to enter

Notes:
• Your name will be visible to all other participants and the organiser
• Once you join, you will be taken to the score submission screen
• You cannot re-join with a different name once submitted

Tip: Use your real name or recognised call sign so the organiser can identify you!
''';

  static const String competitionHistoryScreen = '''
Competition History Screen

Review all your past competition results.

How to use:
• Scroll through your competition history (newest first)
• Each card shows the event, date, your score, X count, and finishing position
• Gold, silver, and bronze colours show 1st, 2nd, and 3rd place finishes
• Tap any entry to see the full podium and standings from that competition

WHAT IS SHOWN:
• Event name and date
• Your score and X count
• Your finishing position (e.g. 3rd of 12)
• Trophy icon for top 3 finishes

Tips:
• Your history builds up over time as you enter more competitions
• Use this to track your improvement across different events
• Full standings from each competition are stored so you can see how everyone placed
''';
}
