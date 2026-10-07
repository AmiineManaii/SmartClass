import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/typography/typography_config.dart';
import '../../../../core/typography/typography_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/health_remote_datasource.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../app/app_providers.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});
  
  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final typographyConfig = ref.watch(typographyConfigProvider);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('settings')),
      ),
      body: typographyConfig.when(
        data: (config) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSection(
              context,
              title: context.tr('appearance'),
              children: [
                _buildThemeModeTile(context, themeMode),
                const Divider(height: 1),
                _buildLanguageTile(context, locale),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              title: context.tr('font_size'),
              children: [
                _buildFontSizeSelector(context, config),
                const Divider(height: 1),
                _buildFontFamilySelector(context, config),
                const Divider(height: 1),
                _buildTextScaleSlider(context, config),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              title: context.tr('notifications_settings'),
              children: [
                _buildSwitchTile(
                  context,
                  title: context.tr('push_notifications'),
                  subtitle: 'Recevoir des notifications push',
                  value: true,
                  onChanged: (value) {},
                  icon: Icons.notifications_rounded,
                  iconColor: colorScheme.primary,
                ),
                const Divider(height: 1, indent: 56),
                _buildSwitchTile(
                  context,
                  title: context.tr('email_notifications'),
                  subtitle: 'Recevoir des notifications par email',
                  value: false,
                  onChanged: (value) {},
                  icon: Icons.email_rounded,
                  iconColor: colorScheme.secondary,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              title: context.tr('data_privacy'),
              children: [
                _buildActionTile(
                  context,
                  title: context.tr('export_data'),
                  subtitle: 'Télécharger toutes vos données',
                  icon: Icons.download_rounded,
                  iconColor: colorScheme.primary,
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 56),
                _buildActionTile(
                  context,
                  title: context.tr('clear_cache'),
                  subtitle: 'Libérer de l\'espace de stockage',
                  icon: Icons.delete_sweep_rounded,
                  iconColor: theme.custom.warningColor,
                  onTap: _clearCache,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              title: context.tr('about'),
              children: [
                _buildActionTile(
                  context,
                  title: context.tr('terms_of_service'),
                  subtitle: 'Lire les conditions d\'utilisation',
                  icon: Icons.description_rounded,
                  iconColor: colorScheme.onSurfaceVariant,
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 56),
                _buildActionTile(
                  context,
                  title: context.tr('privacy_policy'),
                  subtitle: 'Lire la politique de confidentialité',
                  icon: Icons.privacy_tip_rounded,
                  iconColor: colorScheme.onSurfaceVariant,
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 56),
                _buildActionTile(
                  context,
                  title: context.tr('open_source_licenses'),
                  subtitle: 'Voir les licences open source',
                  icon: Icons.code_rounded,
                  iconColor: colorScheme.onSurfaceVariant,
                  onTap: () => showLicensePage(context: context),
                ),
                const Divider(height: 1, indent: 56),
                _buildActionTile(
                  context,
                  title: context.tr('send_feedback'),
                  subtitle: 'Nous envoyer vos commentaires',
                  icon: Icons.feedback_rounded,
                  iconColor: colorScheme.primary,
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 56),
                _buildActionTile(
                  context,
                  title: context.tr('rate_app'),
                  subtitle: 'Noter l\'application sur le store',
                  icon: Icons.star_rate_rounded,
                  iconColor: Colors.amber,
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 56),
                _buildServerStatusTile(context),
              ],
            ),
            const SizedBox(height: 24),
            _buildVersionInfo(context),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Text('Erreur de chargement des paramètres'),
        ),
      ),
    );
  }
  
  Widget _buildSection(BuildContext context, {required String title, required List<Widget> children}) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
        ),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(children: children),
        ),
      ],
    );
  }
  
  Widget _buildThemeModeTile(BuildContext context, ThemeMode themeMode) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.palette_rounded, color: colorScheme.onPrimaryContainer, size: 22),
      ),
      title: Text(context.tr('theme_mode')),
      subtitle: Text(_getThemeModeLabel(themeMode)),
      trailing: PopupMenuButton<ThemeMode>(
        initialValue: themeMode,
        onSelected: (mode) => ref.read(themeModeProvider.notifier).state = mode,
        itemBuilder: (context) => [
          PopupMenuItem(value: ThemeMode.light, child: Text(context.tr('light_mode'))),
          PopupMenuItem(value: ThemeMode.dark, child: Text(context.tr('dark_mode'))),
          PopupMenuItem(value: ThemeMode.system, child: Text(context.tr('system_mode'))),
        ],
        child: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
  
  String _getThemeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Mode clair';
      case ThemeMode.dark:
        return 'Mode sombre';
      case ThemeMode.system:
        return 'Système';
    }
  }
  
  Widget _buildLanguageTile(BuildContext context, String locale) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.language_rounded, color: colorScheme.onSecondaryContainer, size: 22),
      ),
      title: Text(context.tr('language')),
      subtitle: Text(locale == 'fr' ? 'Français' : 'English'),
      trailing: PopupMenuButton<String>(
        initialValue: locale,
        onSelected: (lang) => ref.read(localeProvider.notifier).state = lang,
        itemBuilder: (context) => [
          PopupMenuItem(value: 'fr', child: Text('Français')),
          PopupMenuItem(value: 'en', child: Text('English')),
        ],
        child: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
  
  Widget _buildFontSizeSelector(BuildContext context, TypographyConfig config) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('font_size'),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: FontSizeOption.values.map((option) {
              final isSelected = config.fontSize == option;
              return FilterChip(
                label: Text(_getFontSizeLabel(option)),
                selected: isSelected,
                onSelected: (_) => ref.read(typographyConfigProvider.notifier).updateFontSize(option),
                selectedColor: theme.colorScheme.primaryContainer,
                labelStyle: TextStyle(
                  color: isSelected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  String _getFontSizeLabel(FontSizeOption option) {
    switch (option) {
      case FontSizeOption.small:
        return 'Petit';
      case FontSizeOption.medium:
        return 'Moyen';
      case FontSizeOption.large:
        return 'Grand';
      case FontSizeOption.extraLarge:
        return 'Très grand';
    }
  }
  
  Widget _buildFontFamilySelector(BuildContext context, TypographyConfig config) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('font_family'),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: FontFamilyOption.values.map((option) {
              final isSelected = config.fontFamily == option;
              return FilterChip(
                label: Text(option.displayName),
                selected: isSelected,
                onSelected: (_) => ref.read(typographyConfigProvider.notifier).updateFontFamily(option),
                selectedColor: theme.colorScheme.primaryContainer,
                labelStyle: TextStyle(
                  fontFamily: option.fontFamily,
                  color: isSelected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTextScaleSlider(BuildContext context, TypographyConfig config) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Échelle fine: ${(config.textScaleFactor * 100).round()}%',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                'Défaut: 100%',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: config.textScaleFactor,
            min: 0.85,
            max: 1.5,
            divisions: 13,
            label: '${(config.textScaleFactor * 100).round()}%',
            onChanged: (value) => ref.read(typographyConfigProvider.notifier).updateTextScale(value),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('85%', style: theme.textTheme.labelSmall),
              Text('100%', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
              Text('150%', style: theme.textTheme.labelSmall),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => ref.read(typographyConfigProvider.notifier).reset(),
              child: Text('Réinitialiser'),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSwitchTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    required Color iconColor,
  }) {
    final theme = Theme.of(context);
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }
  
  Widget _buildActionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }

  /// Backend diagnostic probes (`GET /health/live`, `GET /health/ready`).
  /// One-shot fetch with user-triggered refresh — never polled.
  Widget _buildServerStatusTile(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final health = ref.watch(serverHealthProvider);

    final (String subtitle, Color dotColor, Widget? trailing) = health.when(
      data: (status) {
        final online = status.ready && status.alive;
        final detail = status.dbLatencyMs != null
            ? context.tr('server_db_latency', args: {'ms': '${status.dbLatencyMs}'})
            : (online ? context.tr('server_online') : context.tr('server_offline'));
        return (
          detail,
          online ? colorScheme.tertiary : colorScheme.error,
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: context.tr('try_again'),
            onPressed: () => ref.invalidate(serverHealthProvider),
          ),
        );
      },
      loading: () => (
        context.tr('server_checking'),
        colorScheme.outline,
        const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, _) => (
        context.tr('server_offline'),
        colorScheme.error,
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          tooltip: context.tr('try_again'),
          onPressed: () => ref.invalidate(serverHealthProvider),
        ),
      ),
    );

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: dotColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.dns_rounded, color: dotColor, size: 22),
      ),
      title: Text(context.tr('server_status')),
      subtitle: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(child: Text(subtitle)),
        ],
      ),
      trailing: trailing,
    );
  }

  Widget _buildVersionInfo(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(
            Icons.school_rounded,
            size: 48,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'SmartClass',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Version 1.0.0',
            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            'Plateforme intelligente et collaborative d\'apprentissage',
            style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  void _clearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('clear_cache')),
        content: Text('Cela supprimera les fichiers temporaires. Vos données personnelles ne seront pas affectées.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Cache vidé')),
              );
            },
            child: Text(context.tr('clear_cache')),
          ),
        ],
      ),
    );
  }
}