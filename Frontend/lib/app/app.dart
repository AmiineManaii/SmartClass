import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_providers.dart';

class SmartClassApp extends ConsumerWidget {
  const SmartClassApp({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const AppProviders(child: SizedBox.shrink());
  }
}