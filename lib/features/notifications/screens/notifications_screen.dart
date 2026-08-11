import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> mockNotifications = [
      {
        'title': 'Scan Completed',
        'message': 'Your document "Thesis_Draft.pdf" has been fully analyzed. You scored a 92 writing score!',
        'time': '2m ago',
        'isRead': false,
        'icon': Icons.check_circle_rounded,
        'color': AppColors.riskSafe,
      },
      {
        'title': 'New Achievement',
        'message': 'You earned the "Original Thinker" badge.',
        'time': '1h ago',
        'isRead': false,
        'icon': Icons.emoji_events_rounded,
        'color': AppColors.tertiary,
      },
      {
        'title': 'High Similarity Detected',
        'message': 'Action needed: Your last scan showed 45% similarity. Review the flagged sections.',
        'time': 'Yesterday',
        'isRead': true,
        'icon': Icons.warning_amber_rounded,
        'color': AppColors.riskCritical,
      },
      {
        'title': 'Weekly Summary',
        'message': 'You checked 5 documents this week. Keep up the good work!',
        'time': '2 days ago',
        'isRead': true,
        'icon': Icons.bar_chart_rounded,
        'color': AppColors.primary,
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.background,
        actions: [
          TextButton(
            onPressed: () {},
            child: Text(
              'Mark all read',
              style: AppTypography.labelSmall.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: mockNotifications.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final notif = mockNotifications[index];
          return _NotificationCard(
            title: notif['title'],
            message: notif['message'],
            time: notif['time'],
            isRead: notif['isRead'],
            icon: notif['icon'],
            color: notif['color'],
          ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideX(begin: 0.1);
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final String title;
  final String message;
  final String time;
  final bool isRead;
  final IconData icon;
  final Color color;

  const _NotificationCard({
    required this.title,
    required this.message,
    required this.time,
    required this.isRead,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRead ? AppColors.surface : AppColors.primarySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRead ? AppColors.borderLight : AppColors.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                      ),
                    ),
                    Text(
                      time,
                      style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: AppTypography.bodySmall.copyWith(
                    color: isRead ? AppColors.textSecondary : AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
