part of '../pages/videoconference_page.dart';
class _TabSessionList extends ConsumerWidget {
  final String tabKey;
  final bool isTeacher;
  final String searchQuery;
  final String emptyTitle;
  final String emptyDesc;
  final IconData emptyIcon;
  final VoidCallback? onSchedule;

  const _TabSessionList({
    required this.tabKey,
    required this.isTeacher,
    required this.searchQuery,
    required this.emptyTitle,
    required this.emptyDesc,
    required this.emptyIcon,
    this.onSchedule,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(videoSessionsProvider(tabKey));

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(videoSessionsProvider(tabKey).notifier).refresh(),
      child: asyncState.when(
        data: (state) {
          final q = searchQuery.toLowerCase().trim();
          final filtered = q.isEmpty
              ? state.sessions
              : state.sessions.where((s) {
                  final matchTitle = s.title.toLowerCase().contains(q);
                  final matchClass =
                      s.className?.toLowerCase().contains(q) ?? false;
                  final matchSubject =
                      s.subject?.toLowerCase().contains(q) ?? false;
                  final matchHost =
                      s.hostName?.toLowerCase().contains(q) ?? false;
                  return matchTitle || matchClass || matchSubject || matchHost;
                }).toList();

          if (filtered.isEmpty) {
            return _buildEmptyState(context);
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 840;

              return NotificationListener<ScrollNotification>(
                onNotification: (scrollInfo) {
                  if (scrollInfo.metrics.pixels >=
                          scrollInfo.metrics.maxScrollExtent - 200 &&
                      state.hasMore &&
                      !state.isLoadingMore) {
                    ref.read(videoSessionsProvider(tabKey).notifier).loadMore();
                  }
                  return false;
                },
                child: isWide
                    ? GridView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 14,
                          mainAxisExtent: 242,
                        ),
                        itemCount: filtered.length + (state.isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= filtered.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: SmartLoader.small(),
                              ),
                            );
                          }
                          final session = filtered[index];
                          return VideoSessionCard(
                            session: session,
                            isTeacher: isTeacher,
                          );
                        },
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: filtered.length + (state.isLoadingMore ? 1 : 0),
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          if (index >= filtered.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: SmartLoader.small(),
                              ),
                            );
                          }
                          final session = filtered[index];
                          return VideoSessionCard(
                            session: session,
                            isTeacher: isTeacher,
                          );
                        },
                      ),
              );
            },
          );
        },
        loading: () => const Center(
          child: SmartLoader.medium(
            message: 'Chargement des séances de visioconférence...',
          ),
        ),
        error: (err, _) => _buildErrorState(context, ref, err),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final isLiveTab = tabKey == 'live';
    final accentColor = isLiveTab
        ? const Color(0xFFEF4444)
        : (tabKey == 'scheduled' ? const Color(0xFF3B82F6) : const Color(0xFF64748B));

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 540),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF141E33) : colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Concentric halo icon presentation
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: isDark ? 0.14 : 0.08),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                accentColor.withValues(alpha: isDark ? 0.35 : 0.2),
                                accentColor.withValues(alpha: isDark ? 0.15 : 0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            emptyIcon,
                            size: 24,
                            color: isDark ? Colors.white : accentColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Title
                      Text(
                        emptyTitle,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),

                      // Description
                      Text(
                        emptyDesc,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                          height: 1.45,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      // Primary Call to Action for Teachers
                      if (isTeacher && tabKey != 'past') ...[
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: isDark
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF122675),
                            foregroundColor: Colors.white,
                            elevation: 3,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 22, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: Icon(
                            tabKey == 'live'
                                ? Icons.videocam_rounded
                                : Icons.calendar_today_rounded,
                            size: 17,
                          ),
                          label: Text(
                            tabKey == 'live'
                                ? 'Lancer un direct'
                                : 'Programmer une séance',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                          onPressed: onSchedule ?? () => ScheduleSessionDialog.show(context),
                        ),
                      ],

                      // Feature pills footer
                      const SizedBox(height: 24),
                      Divider(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFF1F5F9),
                        height: 1,
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          _buildEmptyFeatureTip(
                            icon: Icons.hd_outlined,
                            text: 'Flux HD 1080p',
                            isDark: isDark,
                          ),
                          _buildEmptyFeatureTip(
                            icon: Icons.present_to_all_rounded,
                            text: 'Partage d\'écran',
                            isDark: isDark,
                          ),
                          _buildEmptyFeatureTip(
                            icon: Icons.fact_check_outlined,
                            text: 'Émargement auto',
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyFeatureTip({
    required IconData icon,
    required String text,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE2E8F0),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object err) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 28,
                color: Color(0xFFDC2626),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Erreur de synchronisation des séances',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              err.toString(),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: Color(0xFFDC2626),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () =>
                  ref.read(videoSessionsProvider(tabKey).notifier).refresh(),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
