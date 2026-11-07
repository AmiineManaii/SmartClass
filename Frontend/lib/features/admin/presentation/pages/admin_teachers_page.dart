import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure_localization.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../application/providers/admin_providers.dart';
import '../../domain/entities/admin_person.dart';
import '../../domain/entities/managed_class.dart';
import '../../domain/repositories/admin_repository.dart';
import '../widgets/admin_person_avatar.dart';
import '../widgets/admin_search_field.dart';
import '../views/web_admin_teachers_view.dart';
import '../../../../core/widgets/smart_loader.dart';

part '../widgets/admin_teachers_page_state.dart';

class AdminTeachersPage extends ConsumerStatefulWidget {
  const AdminTeachersPage({super.key});

  @override
  ConsumerState<AdminTeachersPage> createState() => _AdminTeachersPageState();
}
