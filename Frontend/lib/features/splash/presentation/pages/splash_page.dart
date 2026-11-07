import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/web_controls_bar.dart';

import '../widgets/web_splash_view.dart';

part '../widgets/splash_page_state.dart';

/// Un écran de démarrage (Splash Screen) prestigieux, sobre et professionnel,
/// directement inspiré du nouveau logo SmartClass (Livre ouvert + Réseau IA + Étoile dorée).
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}
