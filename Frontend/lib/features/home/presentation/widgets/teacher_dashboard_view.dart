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

part 'teacher_dashboard_dashboarderror.dart';
part 'teacher_dashboard_noclassnotice.dart';
part 'teacher_dashboard_dashboardbody.dart';
part 'teacher_dashboard_teachersearchbar.dart';
part 'teacher_dashboard_searchshortcutchip.dart';
part 'teacher_dashboard_emptysearchcard.dart';
part 'teacher_dashboard_quicktoolsgrid.dart';
part 'teacher_dashboard_quicktoolitem.dart';
part 'teacher_dashboard_toolcard.dart';
part 'teacher_dashboard_nextslotpill.dart';
part 'teacher_dashboard_statcard.dart';
part 'teacher_dashboard_teacherclasscard.dart';
part 'teacher_dashboard_toptitlerow.dart';
part 'teacher_dashboard_teachercalendarsheet.dart';
part 'teacher_dashboard_teachernotificationssheet.dart';
part 'teacher_dashboard_notificationitem.dart';

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

