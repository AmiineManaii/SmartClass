import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import 'exam_ai_score_page.dart';
import 'secure_exam_page.dart';

class ExamsPage extends ConsumerStatefulWidget {
  const ExamsPage({super.key});

  @override
  ConsumerState<ExamsPage> createState() => _ExamsPageState();
}

class _ExamsPageState extends ConsumerState<ExamsPage> {
  String _selectedTab = 'upcoming'; // 'upcoming', 'in_progress', 'completed'
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final text = _searchController.text.trim().toLowerCase();
      if (text != _searchQuery) {
        setState(() => _searchQuery = text);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(authStateProvider).valueOrNull?.role?.toLowerCase();
    final isTeacher = role == 'teacher' || role == 'admin';

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDesktop = context.screenWidth >= 1024;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 1. Hero Header Banner
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isDesktop ? 32 : 16,
                  16,
                  isDesktop ? 32 : 16,
                  12,
                ),
                child: _buildHeroBanner(context, isTeacher: isTeacher),
              ),
            ),

            // 2. Search & Segmented Pill Tabs
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 32 : 16,
                  vertical: 6,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Search bar
                    _buildSearchBar(context),
                    const SizedBox(height: 12),
                    // Segmented Tabs
                    _buildSegmentedTabs(context),
                  ],
                ),
              ),
            ),

            // 3. Exam List
            _buildSliverExamList(context, isTeacher: isTeacher, isDesktop: isDesktop),

            const SliverToBoxAdapter(
              child: SizedBox(height: 32),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context, {required bool isTeacher}) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF122675), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF122675).withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -40,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.assignment_turned_in_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF38BDF8),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'ÉVALUATIONS SURVEILLÉES & BARÈMES IA',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isTeacher
                                ? context.tr('nav_exams_grades')
                                : context.tr('my_exams'),
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  isTeacher
                      ? 'Planifiez vos épreuves, activez la surveillance anti-fraude en temps réel et générez des barèmes de notation automatisés.'
                      : 'Consultez vos examens programmés, vos simulations d\'entraînement et analysez vos rapports de compétences détaillés.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.88),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (isTeacher)
                      Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () => _showCreateExamDialog(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_rounded,
                                    color: Color(0xFF122675), size: 18),
                                SizedBox(width: 6),
                                Text(
                                  'Créer un examen',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF122675),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    Material(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => _showCreateExamDialog(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.psychology_rounded,
                                  color: Colors.white, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Simulation IA',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? colorScheme.outlineVariant.withValues(alpha: 0.3)
              : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher un examen, matière ou statut...',
          hintStyle: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: colorScheme.onSurfaceVariant,
            size: 20,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () => _searchController.clear(),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentedTabs(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildPillTab(
            keyId: 'upcoming',
            label: context.tr('upcoming'),
            icon: Icons.event_available_rounded,
            badgeText: '2',
          ),
          const SizedBox(width: 8),
          _buildPillTab(
            keyId: 'in_progress',
            label: context.tr('in_progress'),
            icon: Icons.hourglass_top_rounded,
            badgeText: '1',
            isLive: true,
          ),
          const SizedBox(width: 8),
          _buildPillTab(
            keyId: 'completed',
            label: 'Terminés / Notes IA',
            icon: Icons.verified_rounded,
            badgeText: '2',
          ),
        ],
      ),
    );
  }

  Widget _buildPillTab({
    required String keyId,
    required String label,
    required IconData icon,
    required String badgeText,
    bool isLive = false,
  }) {
    final isSelected = _selectedTab == keyId;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedTab = keyId),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF122675)
                : (isDark
                    ? theme.colorScheme.surfaceContainerHigh
                    : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF122675)
                  : (isDark
                      ? theme.colorScheme.outlineVariant.withValues(alpha: 0.2)
                      : const Color(0xFFE2E8F0)),
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF122675).withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLive) ...[
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF22C55E),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ] else ...[
                Icon(
                  icon,
                  size: 15,
                  color: isSelected
                      ? Colors.white
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.2)
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? Colors.white
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverExamList(
    BuildContext context, {
    required bool isTeacher,
    required bool isDesktop,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final allExams = _selectedTab == 'upcoming'
        ? [
            {
              'title': 'Examen final - Programmation OO',
              'date': DateTime.now().add(const Duration(days: 3)),
              'duration': const Duration(minutes: 120),
              'questions': 20,
              'status': 'À venir',
              'isSimulation': false
            },
            {
              'title': 'Simulation - Base de données',
              'date': DateTime.now().add(const Duration(days: 7)),
              'duration': const Duration(minutes: 90),
              'questions': 15,
              'status': 'Simulation',
              'isSimulation': true
            },
          ]
        : _selectedTab == 'in_progress'
            ? [
                {
                  'title': 'Quiz hebdomadaire - Algo',
                  'date': DateTime.now(),
                  'duration': const Duration(minutes: 30),
                  'questions': 10,
                  'status': 'En cours',
                  'isSimulation': false
                },
              ]
            : [
                {
                  'title': 'Examen mi-session - POO',
                  'date': DateTime.now().subtract(const Duration(days: 5)),
                  'duration': const Duration(minutes: 120),
                  'questions': 25,
                  'score': 84,
                  'status': 'Terminé',
                  'isSimulation': false
                },
                {
                  'title': 'Simulation - Structures de données',
                  'date': DateTime.now().subtract(const Duration(days: 12)),
                  'duration': const Duration(minutes: 90),
                  'questions': 20,
                  'score': 92,
                  'status': 'Terminé',
                  'isSimulation': true
                },
              ];

    final filtered = allExams.where((exam) {
      if (_searchQuery.isEmpty) return true;
      final title = (exam['title'] as String? ?? '').toLowerCase();
      final status = (exam['status'] as String? ?? '').toLowerCase();
      return title.contains(_searchQuery) || status.contains(_searchQuery);
    }).toList();

    if (filtered.isEmpty) {
      if (_searchQuery.isNotEmpty) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHigh,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.search_off_rounded,
                      size: 32,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun examen trouvé',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Aucune épreuve ne correspond à "$_searchQuery".',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => _searchController.clear(),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Effacer la recherche'),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildEmptyState(context, _selectedTab, isTeacher),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32 : 16,
        vertical: 12,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final exam = filtered[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppExamCard(
                title: exam['title'] as String,
                date: exam['date'] as DateTime?,
                duration: exam['duration'] as Duration?,
                questionCount: exam['questions'] as int?,
                status: exam['status'] as String,
                statusColor: exam['isSimulation'] == true
                    ? colorScheme.tertiary
                    : colorScheme.primary,
                score: exam['score'] as int?,
                isSimulation: exam['isSimulation'] == true,
                onTap: () {
                  if (_selectedTab == 'completed') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ExamAiScorePage(
                          examTitle: exam['title'] as String,
                          courseContext:
                              'Licence 3 Informatique • Algorithmique Avancée',
                        ),
                      ),
                    );
                  } else {
                    _startExam(context, exam['title'] as String);
                  }
                },
                onStart: _selectedTab == 'upcoming' ||
                        _selectedTab == 'in_progress'
                    ? () => _startExam(context, exam['title'] as String)
                    : null,
              ),
            );
          },
          childCount: filtered.length,
        ),
      ),
    );
  }
  
  Widget _buildEmptyState(BuildContext context, String filter, bool isTeacher) {
    String message;
    IconData icon;
    
    switch (filter) {
      case 'upcoming':
        message = 'Aucun examen à venir';
        icon = Icons.event_available_outlined;
        break;
      case 'in_progress':
        message = 'Aucun examen en cours';
        icon = Icons.hourglass_empty_outlined;
        break;
      default:
        message = 'Aucun examen terminé';
        icon = Icons.check_circle_outline;
    }
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
        child: Column(
          children: [
            Icon(
              icon,
              size: 80,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (filter == 'upcoming') ...[
              const SizedBox(height: 24),
              if (isTeacher)
                AppButton(
                  text: context.tr('create_exam'),
                  onPressed: () => _showCreateExamDialog(context),
                  isFullWidth: false,
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Vos évaluations et épreuves programmées s\'afficheront ici dès leur mise en ligne par vos enseignants.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
  
  void _showCreateExamDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreateExamSheet(),
    );
  }
  
  void _startExam(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Démarrer l\'examen sécurisé'),
        content: Text(
          'Voulez-vous commencer "$title" ?\n\n'
          'Le mode anti-fraude sera activé (surveillance de focus, détection d\'onglet et verrouillage de session).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SecureExamPage(
                    examTitle: title,
                    courseContext: 'Licence 3 Informatique • Algorithmique Avancée',
                  ),
                ),
              );
            },
            child: const Text('Commencer en Mode Sécurisé'),
          ),
        ],
      ),
    );
  }
}

class _CreateExamSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CreateExamSheet> createState() => _CreateExamSheetState();
}

class _CreateExamSheetState extends ConsumerState<_CreateExamSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _durationController = TextEditingController();
  bool _isSimulation = false;
  
  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('create_exam'),
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: context.tr('exam_title'),
                    hintText: 'ex: Examen final - Programmation',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.tr('required_field');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _durationController,
                  decoration: InputDecoration(
                    labelText: context.tr('exam_duration'),
                    hintText: 'Durée en minutes (ex: 120)',
                    prefixIcon: const Icon(Icons.access_time_rounded),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.tr('required_field');
                    }
                    if (int.tryParse(value) == null || int.parse(value) <= 0) {
                      return 'Durée invalide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: Text(context.tr('simulation_exam')),
                  subtitle: Text(context.tr('practice_mode')),
                  value: _isSimulation,
                  onChanged: (value) => setState(() => _isSimulation = value),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        text: context.tr('cancel'),
                        onPressed: () => Navigator.pop(context),
                        variant: AppButtonVariant.outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        text: _isSimulation ? context.tr('generate_exam') : context.tr('create'),
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            Navigator.pop(context);
                            context.showSuccessToast(
                              context.tr(_isSimulation ? 'exam_generated' : 'exam_created'),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}