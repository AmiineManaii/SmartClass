import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure_localization.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/network/api_exception.dart';
import '../../application/providers/course_section_build_provider.dart';
import '../../domain/entities/course_section.dart';
import '../widgets/markdown_course_view.dart';
import '../../../../core/widgets/smart_loader.dart';

part '../widgets/course_section_builder_page_state.dart';
part '../widgets/course_section_builder_state_scroll.dart';
part '../widgets/course_section_builder_state_imageexpl.dart';
part '../widgets/course_section_builder_state_build.dart';
part '../widgets/course_section_builder_state_body.dart';
part '../widgets/course_section_builder_state_progress.dart';
part '../widgets/course_section_builder_state_statbadge.dart';
part '../widgets/course_section_builder_state_navchip.dart';

part '../widgets/course_section_builder_sectioncard.dart';
part '../widgets/course_section_builder_webimagepickerdialog.dart';
part '../widgets/course_section_builder_imageretry.dart';
part '../widgets/course_section_builder_noimagefounddialog.dart';

void _showBuildFailure(BuildContext context, Object error) {
  // ComfyUI unavailable: point the teacher to the web image search.
  if (error is ApiException && error.code == 'IMAGE_SERVICE_UNAVAILABLE') {
    context.showInfoToast(context.tr('ai_build_image_soon'));
    return;
  }
  final String key;
  final Map<String, String> args;
  if (error is ApiException) {
    final l10n = failureL10n(apiExceptionToFailure(error));
    key = l10n.key;
    args = l10n.args;
  } else if (error is Failure) {
    final l10n = failureL10n(error);
    key = l10n.key;
    args = l10n.args;
  } else {
    key = 'something_went_wrong';
    args = const {};
  }
  context.showErrorToast(context.tr(key, args: args));
}

/// Per-section build page (`/courses/:courseId/build`): generate → review →
/// validate each chapter one at a time (RG4/RG27 — the draft only becomes
/// publishable once every section is VALIDATED).
class CourseSectionBuilderPage extends ConsumerStatefulWidget {
  const CourseSectionBuilderPage({super.key, required this.courseId});

  final String courseId;

  @override
  ConsumerState<CourseSectionBuilderPage> createState() =>
      _CourseSectionBuilderPageState();
}
