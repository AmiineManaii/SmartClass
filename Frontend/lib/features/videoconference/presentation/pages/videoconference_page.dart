import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/app_providers.dart';
import '../../../../core/widgets/smart_loader.dart';
import '../../application/videoconference_providers.dart';
import '../widgets/schedule_session_dialog.dart';
import '../widgets/video_session_card.dart';

class VideoconferencePage extends ConsumerStatefulWidget {
  const VideoconferencePage({super.key});

  @override
  ConsumerState<VideoconferencePage> createState() =>
      _VideoconferencePageState();
}

class _VideoconferencePageState extends ConsumerState<VideoconferencePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openScheduleDialog({bool liveNow = false}) async {
    final result = await ScheduleSessionDialog.show(
      context,
      defaultLiveNow: liveNow,
    );
    if (result != null && mounted) {
      ref.read(videoSessionsProvider('live').notifier).refresh();
      ref.read(videoSessionsProvider('scheduled').notifier).refresh();
      ref.read(videoSessionsProvider('past').notifier).refresh();
      if (result == 'live') {
        _tabController.animateTo(0);
      } else if (result == 'scheduled') {
        _tabController.animateTo(1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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

  Widget _buildHeroBanner(
    BuildContext context,
    bool isTeacher,
    bool isDark,
    bool isWide,
    double horizontalPadding,
  ) {
    return Container(
      margin: EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 4),
      padding: EdgeInsets.all(isWide ? 22 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF1E1B4B)]
              : const [Color(0xFF122675), Color(0xFF1E3A8A), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF122675).withValues(alpha: isDark ? 0.35 : 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Faint decorative glow circle in corner
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),

          // Main banner contents
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left Column: Branding, Title, Description, and Badges
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeroHeaderRow(context, isDark),
                      const SizedBox(height: 10),
                      Text(
                        'Participez ou animez des séances interactives avec streaming vidéo temps réel, chat, partage d\'écran et émargement.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureChipsRow(),
                    ],
                  ),
                ),

                // Right Column: Teacher Actions Dock
                if (isTeacher) ...[
                  const SizedBox(width: 24),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF122675),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.videocam_rounded, size: 18),
                          label: const Text(
                            'Lancer un direct',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          onPressed: () => _openScheduleDialog(liveNow: true),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.12),
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.35),
                              width: 1,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.calendar_today_rounded, size: 16),
                          label: const Text(
                            'Programmer une séance',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
                            ),
                          ),
                          onPressed: () => _openScheduleDialog(liveNow: false),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            )
          else
            // Mobile vertical stack
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeroHeaderRow(context, isDark),
                const SizedBox(height: 10),
                Text(
                  'Participez ou animez des séances interactives avec streaming vidéo temps réel, chat, partage d\'écran et émargement.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                _buildFeatureChipsRow(),
                if (isTeacher) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF122675),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.videocam_rounded, size: 17),
                          label: const Text(
                            'Lancer un direct',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          onPressed: () => _openScheduleDialog(liveNow: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.12),
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.35),
                              width: 1,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.calendar_today_rounded, size: 15),
                          label: const Text(
                            'Programmer',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          onPressed: () => _openScheduleDialog(liveNow: false),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildHeroHeaderRow(BuildContext context, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.25),
                    Colors.white.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.videocam_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Directs & Visioconférence',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'LiveKit SFU • Haute Définition',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF34D399).withValues(alpha: 0.6),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFF34D399),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF34D399),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Actif',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureChipsRow() {
    final chips = [
      {'label': '1080p SFU', 'icon': Icons.hd_rounded},
      {'label': '< 100ms', 'icon': Icons.bolt_rounded},
      {'label': 'Partage & Laser', 'icon': Icons.draw_rounded},
      {'label': 'Chiffré E2E', 'icon': Icons.lock_outline_rounded},
    ];

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: chips.map((c) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(c['icon'] as IconData, size: 11, color: Colors.white.withValues(alpha: 0.9)),
              const SizedBox(width: 4),
              Text(
                c['label'] as String,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildControlsToolbar(BuildContext context, bool isDark, bool isWide) {
    if (isWide) {
      return Row(
        children: [
          // Segmented Tabs on Left
          Expanded(
            flex: 3,
            child: _buildSegmentedTabs(context, isDark, isWide: true),
          ),
          const SizedBox(width: 16),
          // Search Bar & Refresh on Right
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Row(
              children: [
                Expanded(child: _buildSearchBar(context, isDark)),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  style: IconButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    foregroundColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.all(10),
                  ),
                  tooltip: 'Actualiser la liste',
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  onPressed: () {
                    final key = _tabController.index == 0
                        ? 'live'
                        : (_tabController.index == 1 ? 'scheduled' : 'past');
                    ref.read(videoSessionsProvider(key).notifier).refresh();
                  },
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Mobile vertical stack
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSearchBar(context, isDark),
        const SizedBox(height: 8),
        _buildSegmentedTabs(context, isDark, isWide: false),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isDark) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _searchQuery.isNotEmpty
              ? (isDark ? const Color(0xFF3B82F6) : const Color(0xFF122675))
              : (isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFE2E8F0)),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            size: 19,
            color: _searchQuery.isNotEmpty
                ? (isDark ? const Color(0xFF60A5FA) : const Color(0xFF122675))
                : const Color(0xFF94A3B8),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              decoration: const InputDecoration(
                hintText: 'Rechercher une séance, matière ou enseignant...',
                hintStyle: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  color: Color(0xFF94A3B8),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchCtrl.clear();
                setState(() => _searchQuery = '');
              },
              child: const Icon(Icons.cancel_rounded,
                  size: 17, color: Color(0xFF94A3B8)),
            ),
        ],
      ),
    );
  }

  Widget _buildSegmentedTabs(BuildContext context, bool isDark, {required bool isWide}) {
    final activeIndex = _tabController.index;

    final tabs = [
      {
        'title': 'En direct',
        'tooltip': 'En direct',
        'icon': Icons.sensors_rounded,
        'selectedIcon': Icons.sensors_rounded,
        'activeColor': const Color(0xFFEF4444),
        'isLive': true,
      },
      {
        'title': 'Programmées',
        'tooltip': 'Programmées',
        'icon': Icons.calendar_today_outlined,
        'selectedIcon': Icons.calendar_month_rounded,
        'activeColor': isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E3A8A),
        'isLive': false,
      },
      {
        'title': 'Historique',
        'tooltip': 'Historique',
        'icon': Icons.history_rounded,
        'selectedIcon': Icons.history_toggle_off_rounded,
        'activeColor': isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
        'isLive': false,
      },
    ];

    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151D2F) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        children: List.generate(tabs.length, (idx) {
          final isSelected = activeIndex == idx;
          final item = tabs[idx];
          final isLive = item['isLive'] as bool;
          final activeColor = item['activeColor'] as Color;
          final title = item['title'] as String;

          return Expanded(
            child: Tooltip(
              message: item['tooltip'] as String,
              child: GestureDetector(
                onTap: () => _tabController.animateTo(idx),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.12)
                                : const Color(0xFFE2E8F0),
                            width: 1,
                          )
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: (isDark ? Colors.black : const Color(0xFF0F172A))
                                  .withValues(alpha: isDark ? 0.35 : 0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            (isSelected ? item['selectedIcon'] : item['icon']) as IconData,
                            size: 18,
                            color: isSelected
                                ? activeColor
                                : (isDark
                                    ? const Color(0xFF64748B)
                                    : const Color(0xFF94A3B8)),
                          ),
                          if (isLive)
                            Positioned(
                              top: -2,
                              right: -3,
                              child: Container(
                                width: 6.5,
                                height: 6.5,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFEF4444).withValues(alpha: 0.8),
                                      blurRadius: 4,
                                      spreadRadius: 0.5,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected
                                ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                : (isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

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
                          mainAxisExtent: 220,
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