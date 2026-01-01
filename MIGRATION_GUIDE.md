# Migration Guide - Mealy App Updates

## For Developers

### Backend Setup

No additional backend setup required. The changes are backward compatible.

### Flutter App Setup

1. **Install new dependencies:**
   ```bash
   cd my_app
   flutter pub get
   ```

2. **For iOS:** Update notification permissions in Info.plist if needed
3. **For Android:** Notification permissions are handled automatically

### Environment Variables

No new environment variables required.

## For End Users

### First Time After Update

1. **Existing Users:**
   - No action required
   - Your data will be preserved
   - You can optionally visit Profile > Notifications to customize notification settings

2. **New Users:**
   - After signing up, you'll see a welcome onboarding flow
   - You can skip any step or complete all 5 steps
   - Your preferences will be saved to personalize your experience

### New Features Available

1. **Shopping List** (Main Menu)
   - Access from the navigation bar
   - Add items manually or generate from habits
   - Organize by categories
   - Track your shopping progress

2. **Notification Settings** (Profile > Notifications)
   - Enable/disable reminders
   - Set custom times for each reminder
   - Control when you receive alerts

3. **Onboarding** (New Users Only)
   - Personalize your experience
   - Set nutrition goals automatically
   - Add initial fridge items
   - Select dietary preferences

## Breaking Changes

### None

This update is fully backward compatible. No breaking changes for existing users.

## Troubleshooting

### Notifications Not Appearing

**iOS:**
1. Go to Settings > Mealy > Notifications
2. Ensure "Allow Notifications" is enabled

**Android:**
1. Go to Settings > Apps > Mealy > Notifications
2. Ensure notifications are enabled

### Shopping List Not Saving

- Shopping list is stored locally on your device
- If the app data is cleared, the shopping list will be reset
- Consider adding items again if this occurs

### Onboarding Appearing for Existing Users

- This should not happen
- If it does, you can skip the onboarding
- Contact support if the issue persists

## Support

For issues or questions:
- Check the IMPLEMENTATION_SUMMARY.md for detailed feature documentation
- Report bugs via GitHub issues
- Contact the development team

## Rollback Instructions

If you need to rollback to the previous version:

1. **Backend:**
   ```bash
   git checkout <previous-commit-hash>
   ```

2. **Flutter:**
   ```bash
   git checkout <previous-commit-hash>
   flutter pub get
   ```

3. Clear app data on devices to reset to default state

## Version Compatibility

- **Minimum Flutter SDK:** 3.9.2
- **Minimum Android SDK:** 21 (Android 5.0)
- **Minimum iOS Version:** 12.0
- **Backend:** Python 3.8+
- **Firebase:** Admin SDK 6.5.0+
