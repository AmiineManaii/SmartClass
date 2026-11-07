import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/smart_loader.dart';
import '../../../home/application/providers/student_dashboard_provider.dart';
import '../widgets/class_invitation_sheet.dart';

part '../widgets/groups_page_state.dart';
part '../widgets/groups_state_build.dart';
part '../widgets/groups_state_hero.dart';
part '../widgets/groups_state_search.dart';
part '../widgets/groups_state_filterchip.dart';
part '../widgets/groups_state_sliver.dart';
part '../widgets/groups_state_empty.dart';
part '../widgets/groups_state_createdialog.dart';
part '../widgets/groups_state_joindialog.dart';
part '../widgets/groups_state_confirmeleave.dart';
part '../widgets/groups_create_group_sheet.dart';

class GroupsPage extends ConsumerStatefulWidget {
  const GroupsPage({super.key});

  @override
  ConsumerState<GroupsPage> createState() => _GroupsPageState();
}
