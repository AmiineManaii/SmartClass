import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Transparent wrapper maintaining interface compatibility.
/// The unified desktop navigation shell is provided by [WebMainScaffold].
class WebAdminScaffold extends ConsumerWidget {
  final String activePath;
  final Widget body;
  final String? breadcrumbCategory;
  final String? breadcrumbCurrent;

  const WebAdminScaffold({
    super.key,
    required this.activePath,
    required this.body,
    this.breadcrumbCategory,
    this.breadcrumbCurrent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return body;
  }
}
