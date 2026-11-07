import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure_localization.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/app_picker_row.dart';
import '../../../../core/widgets/smart_loader.dart';
import '../../application/providers/ai_course_options_provider.dart';
import '../../application/providers/course_generation_job_provider.dart';
import '../../application/providers/course_plan_job_provider.dart';
import '../../application/providers/courses_provider.dart';
import '../../domain/entities/course_outline.dart';
import '../widgets/ai_section_refine_dialog.dart';
import '../widgets/course_outline_editor_card.dart';
import '../widgets/markdown_course_view.dart';

part '../widgets/ai_course_creator_page_state.dart';
part '../widgets/ai_course_creator_state_logic.dart';
part '../widgets/ai_course_creator_state_build.dart';
part '../widgets/ai_course_creator_state_header.dart';
part '../widgets/ai_course_creator_state_source.dart';
part '../widgets/ai_course_creator_state_settings.dart';
part '../widgets/ai_course_creator_state_canvas.dart';
part '../widgets/ai_course_creator_modechip.dart';
part '../widgets/ai_course_creator_resultcard.dart';
part '../widgets/ai_course_creator_editorcard.dart';
part '../widgets/ai_course_creator_liveprogresscard.dart';
part '../widgets/ai_course_creator_pulsingdot.dart';
part '../widgets/ai_course_creator_streamingpreview.dart';
part '../widgets/ai_course_creator_extrasbox.dart';
part '../widgets/ai_course_creator_suggestionchip.dart';
part '../widgets/ai_course_creator_aiactionchip.dart';
part '../widgets/ai_course_creator_generationerrorcard.dart';
part '../widgets/ai_course_creator_desktopmodecard.dart';
part '../widgets/ai_course_creator_segmentpill.dart';

const _genLevels = ['concis', 'equilibre', 'detaille'];

String _levelLabel(BuildContext context, String level) {
  switch (level) {
    case 'concis':
      return context.tr('ai_level_short');
    case 'detaille':
      return context.tr('ai_level_detailed');
    default:
      return context.tr('ai_level_standard');
  }
}

String _difficultyLabel(BuildContext context, String difficulty) {
  switch (difficulty) {
    case 'facile':
      return context.tr('ai_diff_easy');
    case 'difficile':
      return context.tr('ai_diff_hard');
    default:
      return context.tr('ai_diff_medium');
  }
}

class AiCourseCreatorPage extends ConsumerStatefulWidget {
  const AiCourseCreatorPage({super.key});

  @override
  ConsumerState<AiCourseCreatorPage> createState() =>
      _AiCourseCreatorPageState();
}
