import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure_localization.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../application/providers/admin_providers.dart';
import '../../domain/entities/admin_person.dart';
import '../../domain/entities/managed_class.dart';
import '../../domain/repositories/admin_repository.dart';
import '../../infrastructure/models/admin_models.dart';
import '../widgets/admin_field_label.dart';

part '../widgets/class_create_page_state.dart';
part '../widgets/class_create_state_logic.dart';
part '../widgets/class_create_state_build.dart';
part '../widgets/class_create_state_desktop.dart';
part '../widgets/class_create_state_righthub.dart';
part '../widgets/class_create_state_sections.dart';
part '../widgets/class_create_state_mobile.dart';

class ClassCreatePage extends ConsumerStatefulWidget {
  final String? editClassId;

  const ClassCreatePage({this.editClassId, super.key});

  @override
  ConsumerState<ClassCreatePage> createState() => _ClassCreatePageState();
}
