import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../courses/application/providers/courses_provider.dart';
import '../../../home/application/providers/student_dashboard_provider.dart';
import '../../../home/application/providers/teacher_dashboard_provider.dart';
import '../widgets/class_invitation_sheet.dart';
import '../../../../core/widgets/smart_loader.dart';

part '../widgets/class_detail_page_state.dart';
part '../widgets/class_detail_tabbardelegate.dart';
part '../widgets/class_detail_heroclasscard.dart';
part '../widgets/class_detail_overviewtab.dart';
part '../widgets/class_detail_kpicard.dart';
part '../widgets/class_detail_featurebadge.dart';
part '../widgets/class_detail_adminrow.dart';
part '../widgets/class_detail_studentstab.dart';
part '../widgets/class_detail_coursestab.dart';
part '../widgets/class_detail_teacherentry.dart';
part '../widgets/class_detail_taughtsubject.dart';
part '../widgets/class_detail_teacherstab.dart';
part '../widgets/class_detail_mysubjectscard.dart';
part '../widgets/class_detail_teachercard.dart';
part '../widgets/class_detail_subjectinput.dart';
part '../widgets/class_detail_addsubjectdialog.dart';

class ClassDetailPage extends ConsumerStatefulWidget {
  final String groupId;
  final String? initialTitle;

  const ClassDetailPage({required this.groupId, this.initialTitle, super.key});

  @override
  ConsumerState<ClassDetailPage> createState() => _ClassDetailPageState();
}
