import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Tableau de bord d'accueil & découverte enrichi pour l'étudiant
/// Affiché lorsqu'aucune classe n'est encore rejointe.
/// Propose un accès immédiat au Studio IA, aux modules ouverts,
/// au planning interactif et aux échéances académiques.
class NoClassNotice extends StatelessWidget {
  final VoidCallback? onJoinTap;

  const NoClassNotice({super.key, this.onJoinTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : const Color(0xFFE2E8F0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Hero Promo Card: Join Class
        _buildJoinHeroCard(context, isDark),
        const SizedBox(height: 24),

        // 2. Main Discovery Grid (Desktop 2-columns or Mobile stack)
        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column (7/12)
              Expanded(
                flex: 7,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildAiStudioSection(context, cardBg, borderColor, isDark),
                    const SizedBox(height: 24),
                    _buildRecommendedCoursesSection(
                      context,
                      cardBg,
                      borderColor,
                      isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Right Column (5/12)
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSchedulePreviewCard(cardBg, borderColor, isDark),
                    const SizedBox(height: 20),
                    _buildDeadlinesCard(context, cardBg, borderColor, isDark),
                    const SizedBox(height: 20),
                    _buildCloudStorageNotice(cardBg, borderColor, isDark),
                  ],
                ),
              ),
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildAiStudioSection(context, cardBg, borderColor, isDark),
              const SizedBox(height: 20),
              _buildRecommendedCoursesSection(
                context,
                cardBg,
                borderColor,
                isDark,
              ),
              const SizedBox(height: 20),
              _buildSchedulePreviewCard(cardBg, borderColor, isDark),
              const SizedBox(height: 20),
              _buildDeadlinesCard(context, cardBg, borderColor, isDark),
            ],
          ),
      ],
    );
  }

  Widget _buildJoinHeroCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E3A8A), const Color(0xFF0F172A)]
              : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? const Color(0xFF3B82F6).withValues(alpha: 0.3)
              : const Color(0xFFC7D2FE),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : const Color(0x141E3A8A),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.school_rounded,
              color: Color(0xFF2563EB),
              size: 28,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Rejoindre votre promotion académique',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Promo 2026',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Connectez-vous à votre groupe de classe pour synchroniser vos cours officiels, travaux dirigés supervisés et examens universitaires.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.vpn_key_rounded, size: 16),
                      label: const Text('Rejoindre avec un code'),
                      onPressed: onJoinTap,
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        side: BorderSide(
                          color: isDark
                              ? Colors.white30
                              : const Color(0xFF94A3B8),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.explore_outlined, size: 16),
                      label: Text(
                        'Explorer les cours ouverts',
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () => context.push('/courses'),
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

  Widget _buildAiStudioSection(
    BuildContext context,
    Color cardBg,
    Color borderColor,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFF2563EB),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Studio IA & Outils Pédagogiques',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF83F8CD), Color(0xFF8197FF)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Actif 24/7 ✨',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF002116),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Même sans classe officielle, votre tuteur IA est disponible pour réviser, expliquer vos cours et tester vos connaissances.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 18),
          // 3 Studio Tiles
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 500;
              return isWide
                  ? Row(
                      children: [
                        Expanded(
                          child: _buildStudioTile(
                            icon: Icons.chat_bubble_outline_rounded,
                            title: 'Tuteur Virtuel IA',
                            description:
                                'Posez vos questions sur vos exercices et leçons.',
                            badge: '24/7',
                            gradientColors: [
                              const Color(0xFF2563EB),
                              const Color(0xFF1D4ED8),
                            ],
                            onTap: () => context.push('/ai-assistant'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStudioTile(
                            icon: Icons.quiz_outlined,
                            title: 'Quiz d\'Entraînement',
                            description:
                                'Générez un QCM personnalisé pour évaluer votre niveau.',
                            badge: 'QCM',
                            gradientColors: [
                              const Color(0xFF7C3AED),
                              const Color(0xFF6D28D9),
                            ],
                            onTap: () => context.push('/ai-quiz'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStudioTile(
                            icon: Icons.auto_stories_rounded,
                            title: 'Fiches & Synthèses',
                            description:
                                'Résumez vos cours et extrayez les définitions clés.',
                            badge: 'Synthèse',
                            gradientColors: [
                              const Color(0xFF0D9488),
                              const Color(0xFF0F766E),
                            ],
                            onTap: () => context.push('/ai-revision'),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _buildStudioTile(
                          icon: Icons.chat_bubble_outline_rounded,
                          title: 'Tuteur Virtuel IA',
                          description:
                              'Posez vos questions sur vos exercices et leçons.',
                          badge: '24/7',
                          gradientColors: [
                            const Color(0xFF2563EB),
                            const Color(0xFF1D4ED8),
                          ],
                          onTap: () => context.push('/ai-assistant'),
                        ),
                        const SizedBox(height: 10),
                        _buildStudioTile(
                          icon: Icons.quiz_outlined,
                          title: 'Quiz d\'Entraînement',
                          description:
                              'Générez un QCM personnalisé pour évaluer votre niveau.',
                          badge: 'QCM',
                          gradientColors: [
                            const Color(0xFF7C3AED),
                            const Color(0xFF6D28D9),
                          ],
                          onTap: () => context.push('/ai-quiz'),
                        ),
                        const SizedBox(height: 10),
                        _buildStudioTile(
                          icon: Icons.auto_stories_rounded,
                          title: 'Fiches & Synthèses',
                          description:
                              'Résumez vos cours et extrayez les définitions clés.',
                          badge: 'Synthèse',
                          gradientColors: [
                            const Color(0xFF0D9488),
                            const Color(0xFF0F766E),
                          ],
                          onTap: () => context.push('/ai-revision'),
                        ),
                      ],
                    );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStudioTile({
    required IconData icon,
    required String title,
    required String description,
    required String badge,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: Colors.white, size: 22),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 11,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedCoursesSection(
    BuildContext context,
    Color cardBg,
    Color borderColor,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: Color(0xFF10B981),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Modules recommandés pour votre cursus',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => context.push('/courses'),
                child: const Text('Voir tout'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildCourseItem(
            title: 'Algorithmique & Structures de Données',
            code: 'INF301',
            progress: 0.65,
            lessons: '8 / 12 leçons',
            isDark: isDark,
            onTap: () => context.push('/courses'),
          ),
          const SizedBox(height: 10),
          _buildCourseItem(
            title: 'Bases de Données & Modélisation SQL',
            code: 'INF304',
            progress: 0.40,
            lessons: '4 / 10 leçons',
            isDark: isDark,
            onTap: () => context.push('/courses'),
          ),
          const SizedBox(height: 10),
          _buildCourseItem(
            title: 'Intelligence Artificielle & Machine Learning',
            code: 'INF308',
            progress: 0.20,
            lessons: '2 / 10 leçons',
            isDark: isDark,
            onTap: () => context.push('/courses'),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseItem({
    required String title,
    required String code,
    required double progress,
    required String lessons,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                code.substring(0, 3),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 5,
                            backgroundColor: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        lessons,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchedulePreviewCard(
    Color cardBg,
    Color borderColor,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 16,
                    color: Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Planning type de la journée',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '3 séances',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildScheduleSlot(
            time: '08:30 - 10:30',
            subject: 'Algorithmique Avancée',
            room: 'Amphi B104 • Cours Magistral',
            color: const Color(0xFF2563EB),
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildScheduleSlot(
            time: '14:00 - 16:00',
            subject: 'Mathématiques & Algèbre',
            room: 'Session Live Virtuelle 🔴',
            color: const Color(0xFFEF4444),
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildScheduleSlot(
            time: '16:30 - 18:00',
            subject: 'Atelier de Tutorat IA',
            room: 'Studio IA & Quiz d\'assimilation',
            color: const Color(0xFF10B981),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSlot({
    required String time,
    required String subject,
    required String room,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      subject,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  room,
                  style: TextStyle(
                    fontSize: 10.5,
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
    );
  }

  Widget _buildDeadlinesCard(
    BuildContext context,
    Color cardBg,
    Color borderColor,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
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
          Row(
            children: [
              const Icon(
                Icons.assignment_turned_in_rounded,
                size: 16,
                color: Color(0xFFEAB308),
              ),
              const SizedBox(width: 8),
              Text(
                'Échéances & Examens à venir',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDeadlineItem(
            title: 'Devoir #2 d\'Algorithmique',
            deadline: 'Dans 2 jours (22 Octobre)',
            type: 'Devoir à déposer',
            isUrgent: true,
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildDeadlineItem(
            title: 'QCM d\'Auto-évaluation SQL',
            deadline: 'Dans 5 jours (25 Octobre)',
            type: 'QCM supervisé',
            isUrgent: false,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlineItem({
    required String title,
    required String deadline,
    required String type,
    required bool isUrgent,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            isUrgent ? Icons.error_outline_rounded : Icons.check_circle_outline,
            size: 16,
            color: isUrgent ? const Color(0xFFEF4444) : const Color(0xFF10B981),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  '$type • $deadline',
                  style: TextStyle(
                    fontSize: 10.5,
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
    );
  }

  Widget _buildCloudStorageNotice(
    Color cardBg,
    Color borderColor,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE0E7FF),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_done_rounded,
            color: Color(0xFF2563EB),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ENT Cloud Drive • 14.2 / 50 Go',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Synchronisation automatique de vos devoirs activée.',
                  style: TextStyle(
                    fontSize: 10,
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
    );
  }
}
