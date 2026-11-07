import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/error/failure_localization.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/typography/typography_provider.dart';
import '../../../../core/utils/file_download_helper.dart';

part '../widgets/profile_page_state.dart';
part '../widgets/profile_state_backend1.dart';
part '../widgets/profile_state_backend2.dart';
part '../widgets/profile_state_build.dart';
part '../widgets/profile_state_mobile1.dart';
part '../widgets/profile_state_mobile2.dart';
part '../widgets/profile_state_mobile3.dart';
part '../widgets/profile_state_mobile4.dart';
part '../widgets/profile_state_desktop1.dart';
part '../widgets/profile_state_desktop2.dart';
part '../widgets/profile_state_personal.dart';
part '../widgets/profile_state_security.dart';
part '../widgets/profile_state_security_passkeys.dart';
part '../widgets/profile_state_security_2fa.dart';
part '../widgets/profile_state_security_audit.dart';
part '../widgets/profile_state_notifications.dart';
part '../widgets/profile_state_appearance.dart';
part '../widgets/profile_state_privacy.dart';
part '../widgets/profile_state_privacy_danger.dart';
part '../widgets/profile_state_sessions1.dart';
part '../widgets/profile_state_sessions2.dart';
part '../widgets/profile_state_sessions_totp.dart';
part '../widgets/profile_state_sessions3.dart';
part '../widgets/profile_state_helpers1.dart';
part '../widgets/profile_state_helpers2.dart';

/// Page "Paramètres du compte" (Portail étudiant)
/// Navigation modulaire complète avec 6 onglets interactifs :
/// 0. Profil personnel (avec inputs sans double-bordure)
/// 1. Sécurité & Authentification (Mot de passe, 2FA TOTP, Passkeys, Journal d'audit)
/// 2. Notifications & Alertes (Push, Email, SMS, SmartMentor IA, Heures de silence)
/// 3. Apparence & Thème (Clair/Sombre/Système, Français/Anglais, Zoom typographique)
/// 4. Confidentialité & RGPD (Export de données, Partage de classe, Zone critique)
/// 5. Sessions & Appareils (Session actuelle, Appareils distants, Révocation globale)
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}
