import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';

class StudentAiStudioCard extends StatelessWidget {
  final VoidCallback onCourseSummaryTap;
  final VoidCallback onPracticeQuizTap;

  const StudentAiStudioCard({
    required this.onCourseSummaryTap,
    required this.onPracticeQuizTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: const [
            Color(0xFF1E2F78),
            Color(0xFF132055),
            Color(0xFF1A2868),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10193E).withValues(alpha: isDark ? 0.5 : 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background subtle ambient light
          Positioned(
            bottom: -30,
            right: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3B50AC).withValues(alpha: 0.18),
              ),
            ),
          ),
          // Watermark icon
          Positioned(
            top: 6,
            right: 8,
            child: Icon(
              Icons.auto_awesome,
              size: 68,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      size: 22,
                      color: Color(0xFFF6CE72),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.tr('studio_ia_title'),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 19,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr('studio_ia_desc'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFC7D3F7),
                    height: 1.35,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 16),
                // 2 Action Cards
                LayoutBuilder(
                  builder: (context, constraints) {
                    final card1 = _StudioActionCard(
                      icon: Icons.auto_stories,
                      iconColor: const Color(0xFF5CD8AF),
                      title: context.tr('course_summary'),
                      subtitle: context.tr('course_summary_desc'),
                      actionLabel: context.tr('generate_action'),
                      actionColor: const Color(0xFF5CD8AF),
                      onTap: onCourseSummaryTap,
                    );

                    final card2 = _StudioActionCard(
                      icon: Icons.quiz,
                      iconColor: const Color(0xFF8FA7FF),
                      title: context.tr('practice_quiz'),
                      subtitle: context.tr('practice_quiz_desc'),
                      actionLabel: context.tr('create_action'),
                      actionColor: const Color(0xFF8FA7FF),
                      onTap: onPracticeQuizTap,
                    );

                    if (constraints.maxWidth < 280) {
                      return Column(
                        children: [
                          card1,
                          const SizedBox(height: 10),
                          card2,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: card1),
                        const SizedBox(width: 10),
                        Expanded(child: card2),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StudioActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String actionLabel;
  final Color actionColor;
  final VoidCallback onTap;

  const _StudioActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.actionColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0C1433).withValues(alpha: 0.50),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, size: 20, color: iconColor),
                  ),
                  Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFFB4C0E8),
                  fontSize: 11,
                  height: 1.25,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.10),
                      width: 1,
                    ),
                  ),
                ),
                child: Text(
                  actionLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: actionColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
