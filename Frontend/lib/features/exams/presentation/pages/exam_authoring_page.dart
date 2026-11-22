import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/smart_loader.dart';
import '../../application/providers/exam_providers.dart';
import '../../domain/entities/exam_course_option.dart';
import '../../domain/entities/exam_definition.dart';
import '../../domain/repositories/exam_repository.dart';
import '../widgets/exam_coverage_attribution_card.dart';
import '../widgets/exam_question_editor_card.dart';
import '../widgets/exam_tag.dart';
import '../widgets/exam_ui.dart';

part '../widgets/exam_authoring_state.dart';
part '../widgets/exam_authoring_build.dart';
part '../widgets/exam_authoring_dialogs.dart';

/// Teacher authoring page: manual questions, import preview or AI preview.
/// Previews are never persisted and never create an attempt.
class ExamAuthoringPage extends ConsumerStatefulWidget {
  const ExamAuthoringPage({this.examId, super.key});

  final String? examId;

  @override
  ConsumerState<ExamAuthoringPage> createState() => _ExamAuthoringPageState();
}

class _AiRequest {
  const _AiRequest({
    required this.title,
    required this.difficulty,
    required this.questionCount,
    required this.courseIds,
    this.chapters = const <String>[],
    this.focusTopics = const <String>[],
    this.knowledgeDocumentIds = const <String>[],
    this.includeDrafts = false,
  });

  final String title;
  final String difficulty;
  final int questionCount;
  final List<String> courseIds;
  final List<String> chapters;
  final List<String> focusTopics;
  final List<String> knowledgeDocumentIds;
  final bool includeDrafts;
}
