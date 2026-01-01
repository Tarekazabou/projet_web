import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../utils/app_theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  Map<String, bool> _settings = {};
  bool _isLoading = true;

  // Notification times
  TimeOfDay _nutritionTime = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay _hydrationTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _shoppingTime = const TimeOfDay(hour: 18, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _notificationService.getNotificationSettings();
    setState(() {
      _settings = settings;
      _isLoading = false;
    });
  }

  Future<void> _updateSetting(String key, bool value) async {
    await _notificationService.updateNotificationSettings(key, value);
    setState(() {
      _settings[key] = value;
    });
  }

  Future<void> _selectTime(
    BuildContext context,
    String type,
    TimeOfDay initialTime,
    Function(TimeOfDay) onTimeSelected,
  ) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != initialTime) {
      onTimeSelected(picked);
      
      // Reschedule the notification with new time
      if (type == 'nutrition' && _settings['nutrition_reminder_enabled'] == true) {
        await _notificationService.scheduleNutritionReminder(
          hour: picked.hour,
          minute: picked.minute,
        );
      } else if (type == 'hydration' && _settings['hydration_reminder_enabled'] == true) {
        await _notificationService.scheduleHydrationReminder(
          hour: picked.hour,
          minute: picked.minute,
        );
      } else if (type == 'shopping' && _settings['shopping_reminder_enabled'] == true) {
        await _notificationService.scheduleShoppingReminder(
          hour: picked.hour,
          minute: picked.minute,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$type reminder time updated'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notification Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Notification Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Reminder Notifications',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Get timely reminders to help you stay on track with your health goals',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          
          // Nutrition Reminder
          _buildNotificationCard(
            title: 'Nutrition Tracking',
            description: 'Remind me to log my meals',
            icon: Icons.restaurant,
            iconColor: AppTheme.primary,
            enabled: _settings['nutrition_reminder_enabled'] ?? true,
            time: _nutritionTime,
            onToggle: (value) => _updateSetting('nutrition_reminder_enabled', value),
            onTimeSelect: () => _selectTime(
              context,
              'nutrition',
              _nutritionTime,
              (time) => setState(() => _nutritionTime = time),
            ),
          ),
          const SizedBox(height: 16),
          
          // Hydration Reminder
          _buildNotificationCard(
            title: 'Hydration',
            description: 'Remind me to drink water',
            icon: Icons.water_drop,
            iconColor: AppTheme.waterColor,
            enabled: _settings['hydration_reminder_enabled'] ?? true,
            time: _hydrationTime,
            onToggle: (value) => _updateSetting('hydration_reminder_enabled', value),
            onTimeSelect: () => _selectTime(
              context,
              'hydration',
              _hydrationTime,
              (time) => setState(() => _hydrationTime = time),
            ),
          ),
          const SizedBox(height: 16),
          
          // Shopping Reminder
          _buildNotificationCard(
            title: 'Shopping List',
            description: 'Remind me to review my shopping list',
            icon: Icons.shopping_cart,
            iconColor: AppTheme.accent,
            enabled: _settings['shopping_reminder_enabled'] ?? true,
            time: _shoppingTime,
            onToggle: (value) => _updateSetting('shopping_reminder_enabled', value),
            onTimeSelect: () => _selectTime(
              context,
              'shopping',
              _shoppingTime,
              (time) => setState(() => _shoppingTime = time),
            ),
          ),
          const SizedBox(height: 32),
          
          Text(
            'Alert Notifications',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Get alerts about important events',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          
          // Expiring Items
          _buildSimpleNotificationCard(
            title: 'Expiring Items',
            description: 'Alert me when fridge items are expiring soon',
            icon: Icons.warning_amber_rounded,
            iconColor: AppTheme.warning,
            enabled: _settings['expiring_items_reminder_enabled'] ?? true,
            onToggle: (value) => _updateSetting('expiring_items_reminder_enabled', value),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required bool enabled,
    required TimeOfDay time,
    required Function(bool) onToggle,
    required VoidCallback onTimeSelect,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          SwitchListTile(
            value: enabled,
            onChanged: onToggle,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        description,
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            activeColor: AppTheme.primary,
          ),
          if (enabled)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: InkWell(
                onTap: onTimeSelect,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, color: AppTheme.textSecondary, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'Reminder time',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        time.format(context),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.chevron_right, color: AppTheme.textMuted),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSimpleNotificationCard({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required bool enabled,
    required Function(bool) onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.cardShadow,
      ),
      child: SwitchListTile(
        value: enabled,
        onChanged: onToggle,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        activeColor: AppTheme.primary,
      ),
    );
  }
}
