import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/web_controls_bar.dart';

/// Écran Splash Web épuré, prestigieux et professionnel.
/// Met en avant le grand logo animé officiel, une typographie soignée
/// et une barre de progression minimaliste sans surcharge visuelle.
class WebSplashView extends StatelessWidget {
  final AnimationController ambientController;
  final AnimationController sequenceController;
  final Animation<double> progressValue;
  final Animation<double> starGleam;
  final int statusIndex;
  final bool isDark;
  final VoidCallback onNavigate;

  const WebSplashView({
    super.key,
    required this.ambientController,
    required this.sequenceController,
    required this.progressValue,
    required this.starGleam,
    required this.statusIndex,
    required this.isDark,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0C2B4E);
    final secondaryTextColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final accentTeal = isDark ? const Color(0xFF38BDF8) : const Color(0xFF127494);
    const starGold = Color(0xFFDF9F35);

    final statusMessages = [
      context.tr('splash_loading_1'),
      context.tr('splash_loading_2'),
      context.tr('splash_loading_3'),
    ];
    final currentStatus = statusMessages[statusIndex.clamp(0, 2)];
    final percent = (progressValue.value * 100).toInt();

    final ambientVal = ambientController.value;
    final floatOffset = math.sin(ambientVal * math.pi) * 8.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onNavigate,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.1),
            radius: 1.1,
            colors: isDark
                ? const [
                    Color(0xFF132238),
                    Color(0xFF090E17),
                    Color(0xFF050811),
                  ]
                : const [
                    Color(0xFFF1F5F9),
                    Color(0xFFFFFFFF),
                    Color(0xFFE2E8F0),
                  ],
            stops: const [0.0, 0.65, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // ── 1. Toile d'ondes lumineuses subtiles en arrière-plan ──
            Positioned.fill(
              child: CustomPaint(
                painter: _AmbientGlowPainter(
                  ambientVal: ambientVal,
                  isDark: isDark,
                ),
              ),
            ),

            // ── 2. Barre Supérieure Sobre (Badge + Contrôles Web + Passer) ──
            Positioned(
              top: 24,
              left: 36,
              right: 36,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Badge discret SmartClass
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : Colors.black.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          size: 13,
                          color: starGold,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          context.tr('splash_badge'),
                          style: TextStyle(
                            color: primaryTextColor.withValues(alpha: 0.8),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Contrôles bilingues + Thème + Bouton Passer
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const WebControlsBar(),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: onNavigate,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryTextColor.withValues(alpha: 0.85),
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.white,
                          side: BorderSide(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.16)
                                : const Color(0xFFCBD5E1),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              context.tr('skip'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: primaryTextColor.withValues(alpha: 0.85),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 14,
                              color: primaryTextColor.withValues(alpha: 0.85),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── 3. Cœur Central : Grand Logo Animé & Typographie Professionnelle ──
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Le Grand Logo avec Flottement & Scintillement
                  Transform.translate(
                    offset: Offset(0, -floatOffset),
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        // Halo lumineux sous le logo
                        Positioned(
                          bottom: -12,
                          child: Container(
                            width: 140,
                            height: 24,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0C2B4E).withValues(
                                    alpha: isDark
                                        ? 0.55
                                        : 0.16 + (ambientVal * 0.08),
                                  ),
                                  blurRadius: 36,
                                  spreadRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Logo officiel transparent haute résolution
                        SizedBox(
                          width: 160,
                          height: 160,
                          child: Image.asset(
                            'assets/images/logo_emblem.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.school_rounded,
                              size: 90,
                              color: isDark ? const Color(0xFF38BDF8) : AppTheme.primary,
                            ),
                          ),
                        ),

                        // Étoile dorée scintillante sur le coin supérieur droit
                        Positioned(
                          top: 10,
                          right: 32,
                          child: Transform.scale(
                            scale: starGleam.value,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: starGold.withValues(
                                      alpha: 0.7 * starGleam.value,
                                    ),
                                    blurRadius: 18,
                                    spreadRadius: 6,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.auto_awesome,
                                  size: 16,
                                  color: starGold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Titre SmartClass
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Smart',
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          color: primaryTextColor,
                          letterSpacing: -0.6,
                        ),
                      ),
                      Text(
                        'Class',
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          color: accentTeal,
                          letterSpacing: -0.6,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Tagline sobre et élégante
                  Text(
                    context.tr('splash_tagline'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                      color: secondaryTextColor,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),

                  // Barre de progression minimaliste et raffinée
                  SizedBox(
                    width: 320,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: progressValue.value.clamp(0.0, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF2563EB),
                                    Color(0xFF38BDF8),
                                    Color(0xFF10B981),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF38BDF8)
                                        .withValues(alpha: 0.5),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                currentStatus,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: secondaryTextColor,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$percent%',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: primaryTextColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── 4. Pied de page confidentiel & sécurisé ──
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  context.tr('splash_footer'),
                  style: TextStyle(
                    fontSize: 11,
                    color: secondaryTextColor.withValues(alpha: 0.7),
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Peintre personnalisé pour des lueurs d'ambiance douces et animées.
class _AmbientGlowPainter extends CustomPainter {
  final double ambientVal;
  final bool isDark;

  const _AmbientGlowPainter({
    required this.ambientVal,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final paint1 = Paint()
      ..shader = RadialGradient(
        colors: [
          (isDark ? const Color(0xFF1E3A8A) : const Color(0xFF93C5FD))
              .withValues(alpha: isDark ? 0.25 : 0.18),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(
            size.width * 0.25 + math.sin(ambientVal * math.pi) * 20,
            size.height * 0.35 + math.cos(ambientVal * math.pi) * 15,
          ),
          radius: size.width * 0.28,
        ),
      );
    canvas.drawRect(Offset.zero & size, paint1);

    final paint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          (isDark ? const Color(0xFF0F766E) : const Color(0xFFA7F3D0))
              .withValues(alpha: isDark ? 0.22 : 0.15),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(
            size.width * 0.75 - math.sin(ambientVal * math.pi) * 25,
            size.height * 0.65 - math.cos(ambientVal * math.pi) * 20,
          ),
          radius: size.width * 0.30,
        ),
      );
    canvas.drawRect(Offset.zero & size, paint2);
  }

  @override
  bool shouldRepaint(covariant _AmbientGlowPainter oldDelegate) {
    return oldDelegate.ambientVal != ambientVal ||
        oldDelegate.isDark != isDark;
  }
}
