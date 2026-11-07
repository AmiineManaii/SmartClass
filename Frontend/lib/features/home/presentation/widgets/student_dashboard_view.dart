import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../application/providers/student_dashboard_provider.dart';
import '../../domain/entities/student_assignment.dart';
import '../../domain/entities/student_class_membership.dart';
import '../../domain/entities/today_live_session.dart';
import 'no_class_notice.dart';
import '../../../../core/widgets/smart_loader.dart';
import 'student_ai_studio_card.dart';
import 'student_assignments_section.dart';
import 'student_greeting_header.dart';
import 'student_imminent_live_card.dart';
import '../../../videoconference/application/videoconference_providers.dart';
import '../../../videoconference/domain/entities/session_phase.dart';
import '../../../videoconference/domain/entities/video_session.dart';

part 'student_dashboard_enrolledcontent.dart';
part 'student_dashboard_enrolledclasscard.dart';
part 'student_dashboard_desktopgreetingandstatsheader.dart';
part 'student_dashboard_statmetriccard.dart';
part 'student_dashboard_dailyschedulecard.dart';
part 'student_dashboard_scheduleslot.dart';
part 'student_dashboard_livesection.dart';
part 'student_dashboard_realclassessection.dart';
part 'student_dashboard_animatedclasscard.dart';
part 'student_dashboard_classtag.dart';
part 'student_dashboard_assignmentssection.dart';
part 'student_dashboard_toptitlerow.dart';

class StudentDashboardView extends ConsumerWidget {
  const StudentDashboardView({super.key});

  void _showNoNotifications(BuildContext context) {
    // Honest empty state: no notifications source exists yet
    // (notifications module planned). Never a fake counter.
    context.showInfoToast(
      context.tr('notifications_empty'),
      title: context.tr('notifications'),
    );
  }

  void _showJoinClassDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    bool isLoading = false;
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text('Rejoindre une classe'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Entrez le code d\'invitation partagé par votre enseignant ou administrateur.',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    textCapitalization: TextCapitalization.characters,
                    autofocus: true,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      labelText: 'Code d\'invitation',
                      hintText: 'ex: SC-AB12CD',
                      prefixIcon: const Icon(Icons.vpn_key_rounded),
                      errorText: errorMessage,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final code = controller.text.trim();
                          if (code.isEmpty) {
                            setState(() {
                              errorMessage = 'Veuillez saisir un code';
                            });
                            return;
                          }
                          setState(() {
                            isLoading = true;
                            errorMessage = null;
                          });
                          try {
                            await ref
                                .read(groupsRemoteDataSourceProvider)
                                .joinClass(code);
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                            ref.invalidate(myGroupsProvider);
                            ref.invalidate(studentClassMembershipProvider);
                            ref.invalidate(studentEnrolledCoursesProvider);
                            if (context.mounted) {
                              context.showSuccessToast(
                                'Vous avez rejoint la classe avec succès !',
                              );
                            }
                          } catch (e) {
                            setState(() {
                              isLoading = false;
                              errorMessage = e.toString().replaceFirst(
                                'ApiException: ',
                                '',
                              );
                            });
                          }
                        },
                  child: isLoading
                      ? const SmartLoader.small(
                          color: Colors.white,
                          customSize: 18,
                        )
                      : const Text('Rejoindre'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmLeaveClass(
    BuildContext context,
    WidgetRef ref,
    StudentClassMembership membership,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Quitter la classe'),
          content: Text(
            'Êtes-vous sûr de vouloir quitter la classe "${membership.name}" ? Vous ne pourrez plus accéder aux cours associés sans nouveau code d\'invitation.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Annuler'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  await ref
                      .read(groupsRemoteDataSourceProvider)
                      .leaveClass(membership.id);
                  ref.invalidate(myGroupsProvider);
                  ref.invalidate(studentClassMembershipProvider);
                  ref.invalidate(studentEnrolledCoursesProvider);
                  if (context.mounted) {
                    context.showInfoToast('Vous avez quitté la classe.');
                  }
                } catch (e) {
                  if (context.mounted) {
                    context.showErrorToast(
                      e.toString().replaceFirst('ApiException: ', ''),
                    );
                  }
                }
              },
              child: const Text('Quitter'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = ref.watch(authStateProvider).valueOrNull;
    final membership = ref.watch(studentClassMembershipProvider);
    final isDesktop = context.screenWidth >= 1024;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(myGroupsProvider);
            ref.invalidate(studentClassMembershipProvider);
            ref.invalidate(studentTodayLiveProvider);
            ref.invalidate(nextSessionFeedProvider);
            ref.invalidate(dashboardClassesProvider);
            ref.invalidate(studentAssignmentsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop
                  ? 36
                  : (context.screenWidth >= 600 ? 32 : 20),
              vertical: isDesktop ? 24 : 8,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isDesktop ? 1400 : 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!isDesktop) ...[
                      _TopTitleRow(
                        onProfileTap: () => context.push('/profile'),
                        onNotificationsTap: () => _showNoNotifications(context),
                      ),
                      const SizedBox(height: 16),
                      StudentGreetingHeader(
                        user: user,
                        onNotificationsTap: () => _showNoNotifications(context),
                      ),
                      const SizedBox(height: 16),
                    ] else ...[
                      _DesktopGreetingAndStatsHeader(
                        user: user,
                        onJoinTap: () => _showJoinClassDialog(context, ref),
                      ),
                      const SizedBox(height: 24),
                    ],
                    membership.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: SmartLoader.medium(
                            message: 'Chargement de votre classe...',
                          ),
                        ),
                      ),
                      error: (_, _) => NoClassNotice(
                        onJoinTap: () => _showJoinClassDialog(context, ref),
                      ),
                      data: (membership) => membership == null
                          ? NoClassNotice(
                              onJoinTap: () =>
                                  _showJoinClassDialog(context, ref),
                            )
                          : _EnrolledContent(
                              membership: membership,
                              onLeaveClass: () =>
                                  _confirmLeaveClass(context, ref, membership),
                              onJoinLive: () =>
                                  context.push('/videoconference'),
                              onCourseSummaryTap: () =>
                                  context.push('/ai-revision'),
                              onPracticeQuizTap: () => context.push('/ai-quiz'),
                              onViewAllCourses: () => context.push('/courses'),
                              onCourseTap: (id) => id.isEmpty
                                  ? context.push('/courses')
                                  : context.push('/groups/$id'),
                              onHistoryTap: () => context.push('/exams'),
                              onAssignmentAction: (assignmentId) {
                                if (assignmentId.contains('qcm')) {
                                  context.push('/exams');
                                } else {
                                  context.showInfoToast(
                                    context.tr('deposit_action'),
                                  );
                                }
                              },
                            ),
                    ),
                    const SizedBox(height: 24),
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

/// Full dashboard, rendered only with a real class membership.
