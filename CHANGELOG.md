## [Unreleased]

### Added
- **Notifications:** Complete archetype-based notification system
  - Immediate welcome notifications when habits are created
  - Recurring habit reminders with archetype-themed messages
  - Streak warnings sent 1 hour after reminder time if incomplete
  - Daily AI insights at 9 AM
  - Level up and achievement notifications
  - Do Not Disturb mode (10 PM - 7 AM)
  - Archetype-specific notification channels, colors, and icons
  - Smart default reminder times per archetype
  - Time picker for customizing reminder times

- **Habit Management:** Delete habit button in detail screen
  - Confirmation dialog before deletion
  - Cancels all associated notifications

- **Firebase Cloud Functions:** Smart notification scheduling
  - Habit creation/update/delete triggers
  - Scheduled streak warning checks (every 15 min)
  - Daily AI insights delivery
  - Level up detection and notification

### Changed
- Habit creation now includes reminder time picker with archetype defaults
- All notifications respect user notification settings
- Notification channels now archetype-specific for better organization

### Fixed
- FCM token now properly synced to Firestore
- Do Not Disturb now correctly silences all notification types
