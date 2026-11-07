import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure_localization.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../application/providers/admin_providers.dart';
import '../../domain/entities/managed_class.dart';
import '../widgets/admin_filter_chips.dart';
import '../widgets/admin_search_field.dart';
import '../views/web_admin_classes_view.dart';
import '../../../../core/widgets/smart_loader.dart';

part '../widgets/admin_classes_page_state.dart';

class AdminClassesPage extends ConsumerStatefulWidget {
  const AdminClassesPage({super.key});

  @override
  ConsumerState<AdminClassesPage> createState() => _AdminClassesPageState();
}
