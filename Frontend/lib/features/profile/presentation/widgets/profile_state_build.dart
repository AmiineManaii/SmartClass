// ignore_for_file: unused_element, unused_field, prefer_final_fields
part of '../pages/profile_page.dart';

extension on _ProfilePageState {
  Widget buildProfile(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = context.screenWidth >= 1024;
    final authState = ref.watch(authStateProvider).valueOrNull;
    final role = authState?.role?.toLowerCase() ?? 'student';

    // Palette tokens
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : const Color(0xFFE2E8F0);
    final textMuted = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    if (isDesktop) {
      // 100% UNTOUCHED ORIGINAL DESKTOP WEB LAYOUT
      return Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF0F172A)
            : const Color(0xFFF8FAFC),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Breadcrumbs
                    _buildBreadcrumbs(isDark),
                    const SizedBox(height: 12),

                    // 2. Page Title + Badges + ENT Academic Status
                    _buildHeaderSection(isDark),
                    const SizedBox(height: 28),

                    // 3. Main 2-Column Section (Desktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column: Configuration Menu + Quota Box
                        SizedBox(
                          width: 290,
                          child: _buildLeftMenuColumn(
                            cardBg,
                            borderColor,
                            isDark,
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Right Column: Active Tab Dynamic View
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: _buildActiveTabContent(
                              cardBg,
                              borderColor,
                              isDark,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // 4. Bottom Actions Bar (ENT Sync timestamp & Save/Cancel)
                    _buildBottomBar(cardBg, borderColor, isDark),
                    const SizedBox(height: 20),

                    // 5. Academic Footer legal links
                    _buildFooterLinks(textMuted),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // DEDICATED PREMIUM MOBILE LAYOUT (!isDesktop)
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      appBar: _buildMobileAppBar(context, isDark, role),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Mobile Hero Profile Header (Avatar, Name, Role badge, Email, University, CNE/PPR, ENT Sync)
              _buildMobileHeroHeader(cardBg, borderColor, isDark, role),
              const SizedBox(height: 14),

              // 2. Sleek Horizontal Category Tab Pills Selector
              _buildMobileTabsSelector(cardBg, borderColor, isDark),
              const SizedBox(height: 16),

              // 3. Active Tab Content (Optimized for Mobile)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _buildActiveTabContent(cardBg, borderColor, isDark),
              ),
              const SizedBox(height: 20),

              // 4. Mobile Save & Reset Actions Bar
              _buildMobileBottomActions(cardBg, borderColor, isDark),
              const SizedBox(height: 16),

              // 5. Prominent Mobile Logout Section
              _buildMobileLogoutSection(cardBg, borderColor, isDark),
              const SizedBox(height: 20),

              // 6. Mobile Footer Note
              Center(
                child: Text(
                  'SmartClass © 2026 • Plateforme ENT v2.4.0',
                  style: TextStyle(fontSize: 11, color: textMuted),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // MOBILE DEDICATED COMPONENTS
  // ===========================================================================
}



