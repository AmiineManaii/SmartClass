import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../application/providers/teacher_dashboard_provider.dart';
import '../../application/providers/student_dashboard_provider.dart';
import '../../domain/entities/teacher_dashboard.dart';
import '../../../groups/presentation/widgets/class_invitation_sheet.dart';
import 'ai_create_banner.dart';
import 'teacher_greeting_header.dart';
import 'teacher_imminent_live_card.dart';
import '../../../../core/widgets/smart_loader.dart';
import '../../../videoconference/application/videoconference_providers.dart';
import '../../../videoconference/domain/entities/session_phase.dart';
import '../../../videoconference/domain/entities/video_session.dart';

/// Teacher home, fed only by the real API ([teacherDashboardProvider]:
/// own classes from `GET /groups/mine`, next session from their
/// timetables). A teacher with no class sees the contact-administration
/// notice — never invented stats, sessions or classes.
class TeacherDashboardView extends ConsumerWidget {
  const TeacherDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = ref.watch(authStateProvider).valueOrNull;
    final dashboardAsync = ref.watch(teacherDashboardProvider);
    final data = dashboardAsync.valueOrNull;

    final isDesktop = context.screenWidth >= 1024;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(teacherDashboardProvider);
            ref.invalidate(nextSessionFeedProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 36 : (context.screenWidth >= 600 ? 32 : 20),
              vertical: isDesktop ? 24 : 8,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isDesktop ? 1400 : 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!isDesktop) ...[
                      _TopTitleRow(user: user),
                      const SizedBox(height: 16),
                    ],
                    TeacherGreetingHeader(
                      user: user,
                      onCalendarTap: () => _showCalendarBottomSheet(
                        context,
                        data?.nextSlot,
                        data?.classes ?? const [],
                      ),
                      onNotificationsTap: () => _showNotificationsBottomSheet(
                        context,
                        data,
                      ),
                      onProfileTap: () => context.push('/profile'),
                    ),
                    const SizedBox(height: 16),
                    dashboardAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(
                          child: SmartLoader.medium(
                            message: 'Chargement de votre tableau de bord...',
                          ),
                        ),
                      ),
                      error: (_, _) => _DashboardError(
                        onRetry: () =>
                            ref.invalidate(teacherDashboardProvider),
                      ),
                      data: (d) => d.classes.isEmpty
                          ? _NoClassNotice(
                              onCreateVirtual: () =>
                                  _showCreateVirtualDialog(context, ref),
                            )
                          : _DashboardBody(data: d, isDesktop: isDesktop),
                    ),
                    const SizedBox(height: 96),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void _showCreateVirtualDialog(BuildContext context, WidgetRef ref) {
  final nameCtrl = TextEditingController();
  final capCtrl = TextEditingController(text: '50');
  final descCtrl = TextEditingController();

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Nouvelle classe virtuelle'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nom de la classe',
                hintText: 'ex: Atelier Informatique',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: capCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Capacité maximale',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description (optionnel)',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () async {
            final name = nameCtrl.text.trim();
            if (name.isEmpty) return;
            Navigator.pop(ctx);
            try {
              final remote = ref.read(groupsRemoteDataSourceProvider);
              await remote.createVirtualClassroom(
                name: name,
                capacity: int.tryParse(capCtrl.text.trim()),
                description:
                    descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
              );
              ref.invalidate(teacherDashboardProvider);
              if (!context.mounted) return;
              context.showSuccessToast('Classe virtuelle créée avec succès !');
            } catch (e) {
              if (!context.mounted) return;
              context.showErrorToast(e.toString());
            }
          },
          child: const Text('Créer'),
        ),
      ],
    ),
  );
}

void _showCalendarBottomSheet(
  BuildContext context,
  TeacherNextSlot? nextSlot,
  List<TeacherDashboardClass> classes,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _TeacherCalendarSheet(
      nextSlot: nextSlot,
      classes: classes,
    ),
  );
}

void _showNotificationsBottomSheet(
  BuildContext context,
  TeacherDashboardData? data,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _TeacherNotificationsSheet(
      data: data,
    ),
  );
}

class _DashboardError extends StatelessWidget {
  final VoidCallback onRetry;

  const _DashboardError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          context.tr('something_went_wrong'),
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: onRetry,
          child: Text(context.tr('retry')),
        ),
      ],
    );
  }
}

class _NoClassNotice extends StatelessWidget {
  final VoidCallback? onCreateVirtual;

  const _NoClassNotice({this.onCreateVirtual});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colorScheme.secondaryFixed,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.co_present_outlined,
              color: colorScheme.onSecondaryFixed,
              size: 26,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            context.tr('teacher_no_class'),
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            context.tr('teacher_no_class_desc'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (onCreateVirtual != null) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onCreateVirtual,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Créer une classe virtuelle'),
            ),
          ],
        ],
      ),
    );
  }
}

class _DashboardBody extends ConsumerStatefulWidget {
  final TeacherDashboardData data;
  final bool isDesktop;

  const _DashboardBody({
    required this.data,
    required this.isDesktop,
  });

  @override
  ConsumerState<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends ConsumerState<_DashboardBody> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final nextLiveFeed = ref.watch(nextSessionFeedProvider).valueOrNull;

    final q = _searchQuery.toLowerCase().trim();
    final filteredClasses = q.isEmpty
        ? widget.data.classes
        : widget.data.classes.where((c) {
            final matchName = c.name.toLowerCase().contains(q);
            final matchPromo = c.promoTag.toLowerCase().contains(q);
            final matchSubject =
                c.subjects.any((s) => s.toLowerCase().contains(q));
            return matchName || matchPromo || matchSubject;
          }).toList();

    // Check if query triggers a quick tool shortcut suggestion
    Widget? quickShortcut;
    if (q.isNotEmpty) {
      if (q.contains('direct') ||
          q.contains('reunion') ||
          q.contains('visi') ||
          q.contains('live') ||
          q.contains('meet')) {
        quickShortcut = _SearchShortcutChip(
          icon: Icons.videocam_rounded,
          label: 'Directs & Réunions (LiveKit)',
          color: const Color(0xFFE11D48),
          onTap: () => context.push('/videoconference'),
        );
      } else if (q.contains('ia') ||
          q.contains('quiz') ||
          q.contains('plan') ||
          q.contains('crea') ||
          q.contains('gener')) {
        quickShortcut = _SearchShortcutChip(
          icon: Icons.auto_awesome_rounded,
          label: 'Créateur de cours IA',
          color: const Color(0xFF7C3AED),
          onTap: () => context.push('/courses/ai-create'),
        );
      } else if (q.contains('exam') ||
          q.contains('note') ||
          q.contains('devoir') ||
          q.contains('eval')) {
        quickShortcut = _SearchShortcutChip(
          icon: Icons.assignment_turned_in_rounded,
          label: 'Examens, Devoirs & Notes',
          color: const Color(0xFF059669),
          onTap: () => context.push('/exams'),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Search Bar (on mobile, mirrors web top search bar)
        if (!widget.isDesktop) ...[
          _TeacherSearchBar(
            controller: _searchCtrl,
            focusNode: _searchFocusNode,
            query: _searchQuery,
            onChanged: (val) => setState(() => _searchQuery = val.trim()),
            onClear: () {
              _searchCtrl.clear();
              setState(() => _searchQuery = '');
            },
          ),
          if (quickShortcut != null) ...[
            const SizedBox(height: 8),
            quickShortcut,
          ],
          const SizedBox(height: 16),
        ],

        if (nextLiveFeed?.session != null) ...[
          () {
            final liveSession = nextLiveFeed!.session!;
            final phase = phaseOf(
              liveSession,
              DateTime.now(),
              serverOffset: nextLiveFeed.serverOffset,
            );
            final isEndedOrCanceled =
                liveSession.status == VideoSessionStatus.completed ||
                    liveSession.status == VideoSessionStatus.canceled ||
                    phase == SessionPhase.ended ||
                    phase == SessionPhase.canceled;

            if (isEndedOrCanceled) {
              return const SizedBox.shrink();
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TeacherImminentLiveCard(
                session: liveSession,
                serverOffset: nextLiveFeed.serverOffset,
              ),
            );
          }(),
        ],
        if (widget.data.nextSlot != null) ...[
          _NextSlotPill(slot: widget.data.nextSlot!),
          const SizedBox(height: 16),
        ],

        // KPI Stat Cards (Clickable to jump to classes/courses)
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.school_outlined,
                value: '${widget.data.classes.length}',
                labelKey: 'teacher_stat_classes',
                onTap: () => context.push('/groups'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                icon: Icons.groups_outlined,
                value: '${widget.data.totalStudents}',
                labelKey: 'teacher_stat_students',
                onTap: () => context.push('/groups'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                icon: Icons.book_outlined,
                value: '${widget.data.subjects.length}',
                labelKey: 'teacher_stat_subjects',
                onTap: () => context.push('/courses'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // AI Create Banner
        AiCreateBanner(
          onGenerate: () => context.push('/courses/ai-create'),
        ),
        const SizedBox(height: 20),

        // Quick Tools & Services Grid (Brings web sidebar 1-click tools to mobile)
        if (!widget.isDesktop) ...[
          _QuickToolsGrid(
            classesCount: widget.data.classes.length,
            onNewVirtualClass: () => _showCreateVirtualDialog(context, ref),
            onOpenCalendar: () => _showCalendarBottomSheet(
              context,
              widget.data.nextSlot,
              widget.data.classes,
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Mes Classes Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.tr('my_classes'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text(
                    '${filteredClasses.length}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.add_rounded, size: 14),
                  label: const Text('Classe'),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    textStyle: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9999),
                    ),
                  ),
                  onPressed: () => _showCreateVirtualDialog(context, ref),
                ),
                const SizedBox(width: 6),
                TextButton(
                  onPressed: () => context.push('/groups'),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Voir tout',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: theme.colorScheme.secondary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Classes List or Empty Search
        if (filteredClasses.isEmpty)
          _EmptySearchCard(
            query: _searchQuery,
            onReset: () {
              _searchCtrl.clear();
              setState(() => _searchQuery = '');
            },
          )
        else
          for (int i = 0; i < filteredClasses.length; i++) ...[
            _TeacherClassCard(teacherClass: filteredClasses[i]),
            if (i < filteredClasses.length - 1) const SizedBox(height: 16),
          ],
      ],
    );
  }
}

class _TeacherSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _TeacherSearchBar({
    required this.controller,
    required this.focusNode,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: query.isNotEmpty
              ? colorScheme.primary
              : (isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : const Color(0xFFE2E8F0)),
          width: query.isNotEmpty ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            size: 20,
            color: query.isNotEmpty
                ? colorScheme.primary
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: 'Rechercher une classe, un devoir...',
                hintStyle: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  color: isDark
                      ? const Color(0xFF64748B)
                      : const Color(0xFF94A3B8),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (query.isNotEmpty)
            GestureDetector(
              onTap: onClear,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.cancel_rounded,
                  size: 18,
                  color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                '⌘K',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchShortcutChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SearchShortcutChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Accès rapide : $label',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_rounded, size: 14, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptySearchCard extends StatelessWidget {
  final String query;
  final VoidCallback onReset;

  const _EmptySearchCard({
    required this.query,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 24,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Aucune classe trouvée pour "$query"',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Recherchez par nom de classe, promotion ou intitulé de matière.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.refresh_rounded, size: 14),
            label: const Text('Effacer la recherche'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickToolsGrid extends StatelessWidget {
  final int classesCount;
  final VoidCallback onNewVirtualClass;
  final VoidCallback onOpenCalendar;

  const _QuickToolsGrid({
    required this.classesCount,
    required this.onNewVirtualClass,
    required this.onOpenCalendar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final tools = [
      _QuickToolItem(
        icon: Icons.videocam_rounded,
        title: 'Directs & Réunions',
        subtitle: 'LiveKit HD • Émargement',
        gradientColors: const [Color(0xFFE11D48), Color(0xFFBE123C)],
        badgeText: 'LIVE',
        badgeColor: const Color(0xFFEF4444),
        onTap: () => context.push('/videoconference'),
      ),
      _QuickToolItem(
        icon: Icons.auto_awesome_rounded,
        title: 'Créateur IA',
        subtitle: 'Cours, quiz & fiches',
        gradientColors: const [Color(0xFF7C3AED), Color(0xFF6D28D9)],
        badgeText: 'IA +',
        badgeColor: const Color(0xFF8B5CF6),
        onTap: () => context.push('/courses/ai-create'),
      ),
      _QuickToolItem(
        icon: Icons.assignment_turned_in_rounded,
        title: 'Examens & Notes',
        subtitle: 'Corrections & barèmes',
        gradientColors: const [Color(0xFF059669), Color(0xFF047857)],
        badgeText: null,
        badgeColor: null,
        onTap: () => context.push('/exams'),
      ),
      _QuickToolItem(
        icon: Icons.calendar_month_rounded,
        title: 'Planning & Séances',
        subtitle: 'Emploi du temps & agenda',
        gradientColors: const [Color(0xFFD97706), Color(0xFFB45309)],
        badgeText: null,
        badgeColor: null,
        onTap: onOpenCalendar,
      ),
      _QuickToolItem(
        icon: Icons.school_rounded,
        title: 'Mes Classes',
        subtitle: '$classesCount classes actives',
        gradientColors: const [Color(0xFF2563EB), Color(0xFF1D4ED8)],
        badgeText: null,
        badgeColor: null,
        onTap: () => context.push('/groups'),
      ),
      _QuickToolItem(
        icon: Icons.add_circle_outline_rounded,
        title: '+ Classe Virtuelle',
        subtitle: 'Créer un nouvel espace',
        gradientColors: const [Color(0xFF4338CA), Color(0xFF312E81)],
        badgeText: 'NOUVEAU',
        badgeColor: const Color(0xFF6366F1),
        onTap: onNewVirtualClass,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Outils & Services Pédagogiques',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(9999),
                    border:
                        Border.all(color: const Color(0xFFC7D2FE), width: 0.8),
                  ),
                  child: const Text(
                    'Web & Mobile',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFF4338CA),
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final isSmall = constraints.maxWidth < 480;
            final crossAxisCount = isSmall ? 2 : 3;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                mainAxisExtent: 80,
              ),
              itemCount: tools.length,
              itemBuilder: (context, index) {
                final tool = tools[index];
                return _ToolCard(tool: tool);
              },
            );
          },
        ),
      ],
    );
  }
}

class _QuickToolItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final String? badgeText;
  final Color? badgeColor;
  final VoidCallback onTap;

  const _QuickToolItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.onTap,
    this.badgeText,
    this.badgeColor,
  });
}

class _ToolCard extends StatelessWidget {
  final _QuickToolItem tool;

  const _ToolCard({required this.tool});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: tool.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.03),
                offset: const Offset(0, 2),
                blurRadius: 6,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: tool.gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: tool.gradientColors.first.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Icon(tool.icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            tool.title,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (tool.badgeText != null) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: tool.badgeColor!.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              tool.badgeText!,
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                color: tool.badgeColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tool.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NextSlotPill extends StatelessWidget {
  final TeacherNextSlot slot;

  const _NextSlotPill({required this.slot});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () => context.push('/videoconference'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.secondaryFixed.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.secondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.videocam_outlined,
                color: colorScheme.onSecondary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('teacher_next_slot'),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${slot.title} • ${slot.dayLabel} ${slot.start}'
                    '${slot.room != null ? ' • ${slot.room}' : ''}',
                    style: theme.textTheme.labelLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    slot.className,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colorScheme.secondary),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String labelKey;
  final VoidCallback? onTap;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.labelKey,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.04),
                offset: const Offset(0, 1),
                blurRadius: 4,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 18, color: colorScheme.primary),
                  ),
                  if (onTap != null)
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color:
                          colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(value, style: theme.textTheme.headlineSmall),
              Text(
                context.tr(labelKey),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeacherClassCard extends StatelessWidget {
  final TeacherDashboardClass teacherClass;

  const _TeacherClassCard({required this.teacherClass});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () =>
            context.push('/groups/${teacherClass.id}', extra: teacherClass.name),
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFF122675).withValues(alpha: 0.08),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF122675).withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Promo badge + Status chip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.school_rounded,
                          size: 13,
                          color: Color(0xFF4338CA),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          teacherClass.promoTag,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: Color(0xFF4338CA),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFA7F3D0),
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
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'Actif',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: Color(0xFF047857),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Row 2: Class Avatar + Title + Arrow indicator
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF122675), Color(0xFF2E45B8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF122675).withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.class_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          teacherClass.name,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.4,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Gérer les cours & étudiants',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Row 3: Stats row (Students count chip, subjects, next session)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.people_alt_rounded,
                          size: 14,
                          color: Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${teacherClass.memberCount} ${context.tr('stat_students')}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (final subject in teacherClass.subjects)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.menu_book_rounded,
                            size: 13,
                            color: Color(0xFF475569),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            subject,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (teacherClass.nextSessionLabel != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFFDE68A),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 13,
                            color: Color(0xFFD97706),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            teacherClass.nextSessionLabel!,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // Hairline Divider
              const Divider(
                  height: 1, thickness: 0.8, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 12),

              // Row 4: Action Footer (Wrapped to prevent overflow on ultra-narrow devices)
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 8,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => ClassInvitationSheet.show(
                        context,
                        classGroupId: teacherClass.id,
                        className: teacherClass.name,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      child: Ink(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFC7D2FE),
                            width: 0.8,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.key_rounded,
                              size: 15,
                              color: Color(0xFF4338CA),
                            ),
                            SizedBox(width: 6),
                            Text(
                              "Code d'invitation",
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: Color(0xFF4338CA),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Ouvrir la classe',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF122675),
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: Color(0xFF122675),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopTitleRow extends StatelessWidget {
  final AuthState? user;

  const _TopTitleRow({this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left: Logo + ESPACE ENSEIGNANT Badge
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF122675), Color(0xFF2E45B8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(11),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF122675).withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.school_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'SmartClass',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Color(0xFF122675),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'EDTECH',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF312E81)
                        : const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF4338CA)
                          : const Color(0xFFC7D2FE),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.co_present_rounded,
                        size: 11,
                        color: isDark
                            ? const Color(0xFFA5B4FC)
                            : const Color(0xFF6D28D9),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'ESPACE ENSEIGNANT',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: isDark
                              ? const Color(0xFFA5B4FC)
                              : const Color(0xFF6D28D9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),

        // Right: Institution chip (if any) + Profile avatar
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (user?.institution != null &&
                user!.institution!.trim().isNotEmpty) ...[
              Container(
                constraints: const BoxConstraints(maxWidth: 120),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.account_balance_rounded,
                        size: 12, color: colorScheme.primary),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        user!.institution!.trim(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],
            InkWell(
              onTap: () => context.push('/profile'),
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFC7D2FE),
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      (user?.displayName != null &&
                              user!.displayName!.isNotEmpty)
                          ? user!.displayName![0].toUpperCase()
                          : 'P',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: Color(0xFF4338CA),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TeacherCalendarSheet extends StatelessWidget {
  final TeacherNextSlot? nextSlot;
  final List<TeacherDashboardClass> classes;

  const _TeacherCalendarSheet({
    required this.nextSlot,
    required this.classes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: Color(0xFF4338CA),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Planning & Emploi du temps',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          'Vos séances en direct et cours programmés',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (nextSlot != null) ...[
                      Text(
                        'Prochaine séance en direct',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF4338CA),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFC7D2FE),
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4338CA),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.videocam_rounded,
                                        size: 13, color: Colors.white),
                                    SizedBox(width: 4),
                                    Text(
                                      'VISIOCONFÉRENCE',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${nextSlot!.dayLabel} • ${nextSlot!.start}',
                                style: const TextStyle(
                                  color: Color(0xFF312E81),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            nextSlot!.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E1B4B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${nextSlot!.className}${nextSlot!.room != null ? ' • Salle ${nextSlot!.room}' : ''}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF4338CA),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 14),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF4338CA),
                              minimumSize: const Size.fromHeight(40),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.meeting_room_rounded,
                                size: 16),
                            label: const Text('Rejoindre la salle virtuelle'),
                            onPressed: () {
                              Navigator.pop(context);
                              context.push('/videoconference');
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Vos classes & créneaux (${classes.length})',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          context.push('/videoconference');
                        },
                        child: const Text('Directs Live'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (classes.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Aucun créneau programmé pour cette semaine.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    for (final c in classes) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.school_rounded,
                                color: Color(0xFF4338CA),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    c.nextSessionLabel ??
                                        'Créneau selon planning',
                                    style: TextStyle(
                                      color: c.nextSessionLabel != null
                                          ? const Color(0xFFD97706)
                                          : colorScheme.onSurfaceVariant,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_forward_ios_rounded,
                                  size: 14),
                              onPressed: () {
                                Navigator.pop(context);
                                context.push('/groups/${c.id}', extra: c.name);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.video_library_rounded, size: 16),
                    label: const Text('Ouvrir toutes les visioconférences'),
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/videoconference');
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}

class _TeacherNotificationsSheet extends StatelessWidget {
  final TeacherDashboardData? data;

  const _TeacherNotificationsSheet({this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      color: Color(0xFFD97706),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notifications & Activités',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          'Flux d\'actualités et alertes pédagogiques',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.showSuccessToast(
                          'Toutes les notifications sont marquées comme lues');
                    },
                    child: const Text('Tout lire'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (data?.nextSlot != null) ...[
                    _NotificationItem(
                      icon: Icons.alarm_rounded,
                      iconBg: const Color(0xFFFEE2E2),
                      iconColor: const Color(0xFFEF4444),
                      title: 'Séance imminente',
                      body:
                          '${data!.nextSlot!.title} avec ${data!.nextSlot!.className} commence ${data!.nextSlot!.dayLabel} à ${data!.nextSlot!.start}.',
                      time: 'À venir',
                      actionLabel: 'Rejoindre',
                      onAction: () {
                        Navigator.pop(context);
                        context.push('/videoconference');
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  _NotificationItem(
                    icon: Icons.people_alt_rounded,
                    iconBg: const Color(0xFFDBEAFE),
                    iconColor: const Color(0xFF2563EB),
                    title: '${data?.classes.length ?? 0} Classes actives',
                    body:
                        'Vos ${data?.totalStudents ?? 0} étudiants sont synchronisés avec la base académique institutionnelle.',
                    time: 'Aujourd\'hui',
                    actionLabel: 'Gérer',
                    onAction: () {
                      Navigator.pop(context);
                      context.push('/groups');
                    },
                  ),
                  const SizedBox(height: 12),
                  _NotificationItem(
                    icon: Icons.auto_awesome_rounded,
                    iconBg: const Color(0xFFEDE9FE),
                    iconColor: const Color(0xFF7C3AED),
                    title: 'Générateur de cours IA prêt',
                    body:
                        'Générez des plans détaillés, QCM interactifs et fiches d\'exercices en quelques secondes.',
                    time: 'Nouveau',
                    actionLabel: 'Générer',
                    onAction: () {
                      Navigator.pop(context);
                      context.push('/courses/ai-create');
                    },
                  ),
                  const SizedBox(height: 12),
                  _NotificationItem(
                    icon: Icons.assignment_turned_in_rounded,
                    iconBg: const Color(0xFFD1FAE5),
                    iconColor: const Color(0xFF059669),
                    title: 'Examens & Évaluations',
                    body:
                        'Configurez vos examens surveillés et vos barèmes de correction automatisée.',
                    time: 'Rappel',
                    actionLabel: 'Ouvrir',
                    onAction: () {
                      Navigator.pop(context);
                      context.push('/exams');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String body;
  final String time;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _NotificationItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.time,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11.5,
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 2),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: onAction,
                      child: Text(actionLabel!),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
