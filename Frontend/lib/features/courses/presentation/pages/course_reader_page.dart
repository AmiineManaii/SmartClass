import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/smart_loader.dart';
import '../../application/providers/courses_provider.dart';
import './course_reader_body.dart';
import '../widgets/course_reader_error.dart';

/// Lecteur de cours SmartClass — page principale.
///
/// Affiche le contenu Markdown du cours, l'état de construction par sections
/// (PENDING / GENERATED / VALIDATED) et les actions de modération
/// (Valider / Dépublier / Supprimer / Raffiner IA).
///
/// Aucune donnée mockée : tout provient de l'API via les providers Riverpod.
class CourseReaderPage extends ConsumerWidget {
  final String courseId;

  const CourseReaderPage({super.key, required this.courseId});

  Future<void> _copyContent(BuildContext context, String content) async {
    await Clipboard.setData(ClipboardData(text: content));
    if (!context.mounted) return;
    context.showSuccessToast(context.tr('ai_copied'));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courseAsync = ref.watch(generatedCourseProvider(courseId));

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          tooltip: context.tr('back'),
          onPressed: () => context.pop(),
        ),
        title: Text(
          courseAsync.valueOrNull?.title ?? context.tr('course_details'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
          if (courseAsync.valueOrNull != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              tooltip: context.tr('course_export'),
              onSelected: (val) {
                if (val == 'copy') {
                  _copyContent(context, courseAsync.valueOrNull!.content ?? '');
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'copy',
                  child: Row(
                    children: [
                      const Icon(Icons.copy_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text(context.tr('course_export_copy')),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: courseAsync.when(
        loading: () => const Center(
          child: SmartLoader.large(message: 'Chargement du cours...'),
        ),
        error: (error, _) => CourseReaderError(
          error: error,
          onRetry: () => ref.invalidate(generatedCourseProvider(courseId)),
        ),
        data: (course) => CourseReaderBody(
          course: course,
          courseId: courseId,
          onCopy: () => _copyContent(context, course.content ?? ''),
        ),
      ),
    );
  }
}
