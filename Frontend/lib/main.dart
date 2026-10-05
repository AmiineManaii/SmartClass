import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await initializeDateFormatting('fr_FR', null);
  await initializeDateFormatting('en_US', null);
  Intl.defaultLocale = 'fr_FR';
  
  runApp(const ProviderScope(child: SmartClassApp()));
}