import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure_localization.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../application/providers/admin_providers.dart';
import '../../domain/entities/fraud_report.dart';
import '../widgets/admin_filter_chips.dart';
import '../views/web_admin_reports_view.dart';
import '../../../../core/widgets/smart_loader.dart';

part '../widgets/admin_frauds_page_state.dart';

class AdminFraudsPage extends ConsumerStatefulWidget {
  const AdminFraudsPage({super.key});

  @override
  ConsumerState<AdminFraudsPage> createState() => _AdminFraudsPageState();
}
