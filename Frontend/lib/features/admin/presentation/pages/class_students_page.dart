import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure_localization.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_button.dart';
import '../../application/providers/admin_providers.dart';
import '../../domain/entities/admin_person.dart';
import '../widgets/admin_filter_chips.dart';
import '../widgets/admin_person_avatar.dart';
import '../widgets/admin_search_field.dart';

part '../widgets/class_students_page_state.dart';

class ClassStudentsPage extends ConsumerStatefulWidget {
  final String classId;

  const ClassStudentsPage({required this.classId, super.key});

  @override
  ConsumerState<ClassStudentsPage> createState() => _ClassStudentsPageState();
}
