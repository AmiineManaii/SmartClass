part of '../pages/videoconference_page.dart';
extension on _VideoconferencePageState {
  Widget _buildPage(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final role = ref.watch(authStateProvider).valueOrNull?.role?.toLowerCase();
    final isTeacher = role == 'teacher' || role == 'admin';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final horizontalPadding = isWide ? 24.0 : 16.0;

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0B101E) : colorScheme.surface,
          floatingActionButton: isTeacher
              ? FloatingActionButton(
                  backgroundColor: isDark ? const Color(0xFF3B82F6) : const Color(0xFF122675),
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  tooltip: _tabController.index == 0
                      ? 'Lancer un direct'
                      : 'Programmer une séance',
                  onPressed: () => _openScheduleDialog(
                    liveNow: _tabController.index == 0,
                  ),
                  child: Icon(
                    _tabController.index == 0
                        ? Icons.videocam_rounded
                        : Icons.calendar_today_rounded,
                    size: 22,
                  ),
                )
              : null,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Hero Banner
                    _buildHeroBanner(context, isTeacher, isDark, isWide, horizontalPadding),

                    // Controls Toolbar: Search & Segmented Tabs
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        isWide ? 14 : 10,
                        horizontalPadding,
                        8,
                      ),
                      child: _buildControlsToolbar(context, isDark, isWide),
                    ),
                    const SizedBox(height: 4),

                    // Session List per Tab
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _TabSessionList(
                            tabKey: 'live',
                            isTeacher: isTeacher,
                            searchQuery: _searchQuery,
                            emptyTitle: 'Aucun direct en cours',
                            emptyDesc:
                                'Les séances en direct apparaîtront ici dès que leur diffusion commencera.',
                            emptyIcon: Icons.videocam_outlined,
                            onSchedule: () => _openScheduleDialog(liveNow: true),
                          ),
                          _TabSessionList(
                            tabKey: 'scheduled',
                            isTeacher: isTeacher,
                            searchQuery: _searchQuery,
                            emptyTitle: 'Aucune séance programmée',
                            emptyDesc:
                                'Planifiez vos prochains cours virtuels pour qu\'ils s\'affichent à l\'emploi du temps.',
                            emptyIcon: Icons.calendar_month_outlined,
                            onSchedule: () => _openScheduleDialog(liveNow: false),
                          ),
                          _TabSessionList(
                            tabKey: 'past',
                            isTeacher: isTeacher,
                            searchQuery: _searchQuery,
                            emptyTitle: 'Aucun historique récent',
                            emptyDesc:
                                'Les séances terminées et rapports d\'émargement seront archivés ici.',
                            emptyIcon: Icons.history_rounded,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

}
