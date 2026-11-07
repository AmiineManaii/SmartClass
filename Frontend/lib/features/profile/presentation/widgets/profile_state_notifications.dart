// ignore_for_file: unused_element, unused_field, prefer_final_fields
part of '../pages/profile_page.dart';

extension on _ProfilePageState {
  Widget _buildNotificationsCard(Color cardBg, Color borderColor, bool isDark) {
    return Container(
      padding: EdgeInsets.all(context.screenWidth >= 1024 ? 24 : 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E3A8A).withValues(alpha: 0.4)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('menu_notifications'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.tr('notifications_settings_desc'),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 5 Channels
          _buildNotificationSwitchRow(
            icon: Icons.notifications_active_outlined,
            title: context.tr('notif_push_title'),
            subtitle: context.tr('notif_push_desc'),
            value: _pushNotifications,
            isDark: isDark,
            onChanged: (val) {
              updateState(() => _pushNotifications = val);
              _showSuccessSnackBar(
                val
                    ? 'Notifications push activées'
                    : 'Notifications push désactivées',
              );
            },
          ),
          const Divider(height: 20),
          _buildNotificationSwitchRow(
            icon: Icons.mail_outline_rounded,
            title: context.tr('notif_email_title'),
            subtitle: context.tr('notif_email_desc'),
            value: _emailNotifications,
            isDark: isDark,
            onChanged: (val) {
              updateState(() => _emailNotifications = val);
              _showSuccessSnackBar(
                'Préférences email universitaire mises à jour.',
              );
            },
          ),
          const Divider(height: 20),
          _buildNotificationSwitchRow(
            icon: Icons.sms_outlined,
            title: context.tr('notif_sms_title'),
            subtitle: context.tr('notif_sms_desc'),
            value: _smsEmergencyAlerts,
            isDark: isDark,
            onChanged: (val) {
              updateState(() => _smsEmergencyAlerts = val);
              _showSuccessSnackBar('Canal d\'urgence SMS mis à jour.');
            },
          ),
          const Divider(height: 20),
          _buildNotificationSwitchRow(
            icon: Icons.auto_awesome_rounded,
            title: context.tr('notif_ai_mentor_title'),
            subtitle: context.tr('notif_ai_mentor_desc'),
            value: _aiSmartMentorRecommendations,
            badge: 'SmartMentor',
            isDark: isDark,
            onChanged: (val) {
              updateState(() => _aiSmartMentorRecommendations = val);
              _showSuccessSnackBar(
                'Algorithme de révision SmartMentor mis à jour.',
              );
            },
          ),
          const Divider(height: 20),
          _buildNotificationSwitchRow(
            icon: Icons.alarm_rounded,
            title: context.tr('notif_deadlines_title'),
            subtitle: context.tr('notif_deadlines_desc'),
            value: _deadlinesReminders,
            isDark: isDark,
            onChanged: (val) {
              updateState(() => _deadlinesReminders = val);
              _showSuccessSnackBar('Rappels d\'échéances configurés.');
            },
          ),
          const Divider(height: 20),
          _buildNotificationSwitchRow(
            icon: Icons.bedtime_outlined,
            title: context.tr('notif_quiet_hours_title'),
            subtitle: context.tr('notif_quiet_hours_desc'),
            value: _quietHoursEnabled,
            isDark: isDark,
            onChanged: (val) {
              updateState(() => _quietHoursEnabled = val);
              _showSuccessSnackBar(
                val
                    ? 'Heures de silence activées (22:00 - 07:00)'
                    : 'Heures de silence désactivées',
              );
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 3: APPARENCE & THÈME
  // ===========================================================================
}



