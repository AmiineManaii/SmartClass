import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/recording_providers.dart';
import '../../domain/entities/recording_models.dart';

class TeacherReviewChapterTimeline extends ConsumerWidget {
  final String sessionId;
  final List<LessonChapterEntity> chapters;

  const TeacherReviewChapterTimeline({
    super.key,
    required this.sessionId,
    required this.chapters,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentPos = ref.watch(replayPositionSecondsProvider(sessionId));

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? const Color(0xFF334155).withValues(alpha: 0.5)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : const Color(0xFF64748B).withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.auto_stories_rounded,
                      size: 16,
                      color: Color(0xFF60A5FA),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Découpage automatique par IA',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '${chapters.length} chapitres indexés avec la vidéo',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Text(
                  '${chapters.length} chapitres',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Chapter List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: chapters.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final ch = chapters[index];
              final isActive =
                  currentPos >= ch.startSec && currentPos <= ch.endSec;
              final isPast = currentPos > ch.endSec;

              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  ref
                      .read(replayPositionSecondsProvider(sessionId).notifier)
                      .state = ch.startSec;
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isActive
                        ? (isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFEFF6FF))
                        : (isDark
                            ? const Color(0xFF0F1626)
                            : const Color(0xFFF8FAFC)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFF3B82F6)
                          : (isDark
                              ? const Color(0xFF334155).withValues(alpha: 0.4)
                              : const Color(0xFFE2E8F0)),
                      width: isActive ? 1.5 : 1,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Step Indicator Circle
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive
                              ? const Color(0xFF3B82F6)
                              : (isPast
                                  ? const Color(0xFF10B981).withValues(alpha: 0.2)
                                  : (isDark
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFFE2E8F0))),
                          border: Border.all(
                            color: isActive
                                ? const Color(0xFF60A5FA)
                                : (isPast
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF64748B)),
                            width: 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: isActive
                            ? const Icon(Icons.play_arrow_rounded,
                                size: 14, color: Colors.white)
                            : (isPast
                                ? const Icon(Icons.check_rounded,
                                    size: 13, color: Color(0xFF10B981))
                                : Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF64748B),
                                    ),
                                  )),
                      ),
                      const SizedBox(width: 10),

                      // Chapter Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  ch.formattedRange,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isActive
                                        ? const Color(0xFF60A5FA)
                                        : (isDark
                                            ? const Color(0xFF94A3B8)
                                            : const Color(0xFF64748B)),
                                  ),
                                ),
                                if (isActive)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF3B82F6)
                                          .withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'ACTIF',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF60A5FA),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              ch.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            if (ch.summary.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                ch.summary,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
