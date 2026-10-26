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

    return Scaffold(
      backgroundColor: colorScheme.surface,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Hero Banner
            _buildHeroBanner(context, isTeacher, isDark),

            // Search Bar & Filter Controls
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: _buildSearchBar(context, isDark),
            ),

            // Segmented Pill Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: _buildSegmentedTabs(context, isDark),
            ),
            const SizedBox(height: 6),

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
    );
  }

  Widget _buildHeroBanner(BuildContext context, bool isTeacher, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF122675), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF122675).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.videocam_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Directs & Visioconférence',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'LiveKit SFU • Haute Définition',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF34D399).withValues(alpha: 0.6),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF34D399),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Actif',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Participez ou animez des séances interactives avec streaming vidéo temps réel, chat, partage d\'écran et émargement.',
            style: TextStyle(
              fontFamily: 'Inter',
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12,
              height: 1.35,
            ),
          ),
          if (isTeacher) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF122675),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(
                      _tabController.index == 0
                          ? Icons.videocam_rounded
                          : Icons.calendar_today_rounded,
                      size: 18,
                    ),
                    label: Text(
                      _tabController.index == 0
                          ? 'Lancer un direct'
                          : 'Programmer une séance',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                    onPressed: () => _openScheduleDialog(
                      liveNow: _tabController.index == 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isDark) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _searchQuery.isNotEmpty
              ? const Color(0xFF122675)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : const Color(0xFFE2E8F0)),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            size: 18,
            color: _searchQuery.isNotEmpty
                ? const Color(0xFF122675)
                : const Color(0xFF94A3B8),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              decoration: const InputDecoration(
                hintText: 'Rechercher une séance, matière ou enseignant...',
                hintStyle: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
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
                  size: 16, color: Color(0xFF94A3B8)),
            ),
        ],
      ),
    );
  }

  Widget _buildSegmentedTabs(BuildContext context, bool isDark) {
    final activeIndex = _tabController.index;

    final tabs = [
      {
        'tooltip': 'En direct',
        'icon': Icons.sensors_rounded,
        'selectedIcon': Icons.sensors_rounded,
        'activeColor': const Color(0xFFEF4444),
        'isLive': true,
      },
      {
        'tooltip': 'Programmées',
        'icon': Icons.calendar_today_outlined,
        'selectedIcon': Icons.calendar_month_rounded,
        'activeColor': isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E3A8A),
        'isLive': false,
      },
      {
        'tooltip': 'Historique',
        'icon': Icons.history_rounded,
        'selectedIcon': Icons.history_toggle_off_rounded,
        'activeColor': isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
        'isLive': false,
      },
    ];

    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        children: List.generate(tabs.length, (idx) {
          final isSelected = activeIndex == idx;
          final item = tabs[idx];
          final isLive = item['isLive'] as bool;
          final activeColor = item['activeColor'] as Color;

          return Expanded(
            child: Tooltip(
              message: item['tooltip'] as String,
              child: GestureDetector(
                onTap: () => _tabController.animateTo(idx),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: (isDark ? Colors.black : const Color(0xFF0F172A))
                                  .withValues(alpha: isDark ? 0.35 : 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        (isSelected
                            ? item['selectedIcon']
                            : item['icon']) as IconData,
                        size: 20,
                        color: isSelected
                            ? activeColor
                            : (isDark
                                ? const Color(0xFF64748B)
                                : const Color(0xFF94A3B8)),
                      ),
                      if (isLive)
                        Positioned(
                          top: -2,
                          right: -4,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.6),
                                  blurRadius: 4,
                                ),
                              ],
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
            child: ListView.separated(
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

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF2FF),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFC7D2FE),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          emptyIcon,
                          size: 26,
                          color: isDark ? const Color(0xFF818CF8) : const Color(0xFF4338CA),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        emptyTitle,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        emptyDesc,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (isTeacher && tabKey != 'past') ...[
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF122675),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: Icon(
                            tabKey == 'live'
                                ? Icons.videocam_rounded
                                : Icons.calendar_today_rounded,
                            size: 16,
                          ),
                          label: Text(
                            tabKey == 'live'
                                ? 'Lancer un direct'
                                : 'Programmer une séance',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          onPressed: onSchedule ?? () => ScheduleSessionDialog.show(context),
                        ),
                      ],
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

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object err) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  size: 26, color: Color(0xFFDC2626)),
            ),
            const SizedBox(height: 14),
            const Text(
              'Erreur de synchronisation des séances',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              err.toString(),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
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