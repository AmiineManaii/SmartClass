import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure_localization.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../application/providers/admin_providers.dart';
import '../../domain/entities/admin_person.dart';
import '../../domain/entities/managed_class.dart';
import '../widgets/admin_person_avatar.dart';
import '../widgets/admin_search_field.dart';
import '../views/web_admin_students_view.dart';
import '../../../../core/widgets/smart_loader.dart';

part '../widgets/admin_students_page_state.dart';

class AdminStudentsPage extends ConsumerStatefulWidget {
  const AdminStudentsPage({super.key});

  @override
  ConsumerState<AdminStudentsPage> createState() => _AdminStudentsPageState();
}
