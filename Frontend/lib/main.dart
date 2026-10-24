import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/app_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();

  await initializeDateFormatting('fr_FR', null);
  await initializeDateFormatting('en_US', null);
  Intl.defaultLocale = 'fr_FR';

  final prefs = await SharedPreferences.getInstance();
  final hasSeenSplash = prefs.getBool('has_seen_splash') ?? false;
  
  runApp(
    ProviderScope(
      overrides: [
        hasSeenSplashProvider.overrideWith((ref) => hasSeenSplash),
      ],
      child: const SmartClassApp(),
    ),
  );
}