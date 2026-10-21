import 'package:flutter/material.dart';
import '../../../profile/presentation/pages/profile_page.dart';

/// Page "Paramètres" qui renvoie fidèlement vers la maquette complète Stitch
/// unifiée avec les "Paramètres du compte" (Profil, Sécurité, Notifications, Thème).
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfilePage();
  }
}