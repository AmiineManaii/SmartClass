import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../application/providers/admin_providers.dart';
import '../../domain/entities/managed_class.dart';
import '../../domain/entities/timetable.dart';
import '../views/web_admin_planning_view.dart';

part '../widgets/admin_planning_page_state.dart';
part '../widgets/admin_planning_classselector.dart';
part '../widgets/admin_planning_planningbody.dart';
part '../widgets/admin_planning_promocard.dart';
part '../widgets/admin_planning_metachip.dart';
part '../widgets/admin_planning_weeknavigator.dart';
part '../widgets/admin_planning_daystrip.dart';
part '../widgets/admin_planning_daycell.dart';
part '../widgets/admin_planning_weekstats.dart';
part '../widgets/admin_planning_daytimeline.dart';
part '../widgets/admin_planning_timelinerow.dart';
part '../widgets/admin_planning_breakrow.dart';
part '../widgets/admin_planning_typechip.dart';
part '../widgets/admin_planning_sessioncard.dart';
part '../widgets/admin_planning_statusline.dart';
part '../widgets/admin_planning_rawstatusline.dart';
part '../widgets/admin_planning_freeslotcard.dart';

class AdminPlanningPage extends ConsumerStatefulWidget {
  const AdminPlanningPage({super.key});

  @override
  ConsumerState<AdminPlanningPage> createState() => _AdminPlanningPageState();
}
