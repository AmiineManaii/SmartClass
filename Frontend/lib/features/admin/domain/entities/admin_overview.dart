/// Dashboard overview models (pure Dart).
///
/// Backend endpoints: none yet (users/groups/exams modules planned).
/// All values below come from the mock datasource until then.
enum AdminStatTone { info, success, warning, error }

class AdminStat {
  final String id;
  final String icon;
  final String value;
  final String labelKey;
  final String badgeKey;
  final Map<String, String> badgeArgs;
  final AdminStatTone tone;
  final bool highlighted;

  const AdminStat({
    required this.id,
    required this.icon,
    required this.value,
    required this.labelKey,
    required this.badgeKey,
    this.badgeArgs = const {},
    this.tone = AdminStatTone.info,
    this.highlighted = false,
  });
}

class AdminShortcut {
  final String id;
  final String icon;
  final String titleKey;
  final String descKey;
  final String route;

  const AdminShortcut({
    required this.id,
    required this.icon,
    required this.titleKey,
    required this.descKey,
    required this.route,
  });
}

class AdminAlertChip {
  final String text;
  final AdminStatTone tone;

  const AdminAlertChip({required this.text, required this.tone});
}

class AdminOverview {
  final List<AdminStat> stats;
  final List<AdminShortcut> shortcuts;
  final List<AdminAlert> alerts;

  const AdminOverview({
    required this.stats,
    required this.shortcuts,
    required this.alerts,
  });
}

class AdminAlert {
  final String id;
  final String icon;
  final String title;
  final String subtitle;
  final String? meta;
  final List<AdminAlertChip> chips;
  final String primaryActionKey;
  final String? secondaryActionKey;

  const AdminAlert({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.meta,
    this.chips = const [],
    required this.primaryActionKey,
    this.secondaryActionKey,
  });
}
