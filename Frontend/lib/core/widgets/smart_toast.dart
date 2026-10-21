import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

/// Type of toast notification defining its visual theme and icon.
enum ToastType {
  success,
  error,
  warning,
  info,
}

/// Model holding toast data.
class _ToastData {
  final String id;
  final String message;
  final String? title;
  final ToastType type;
  final Duration duration;
  final VoidCallback? onAction;
  final String? actionLabel;

  _ToastData({
    required this.id,
    required this.message,
    this.title,
    this.type = ToastType.info,
    this.duration = const Duration(milliseconds: 3500),
    this.onAction,
    this.actionLabel,
  });
}

/// Global Toast Manager that controls floating modern toast notifications across the app.
class SmartToast {
  static OverlayEntry? _overlayEntry;
  static final List<_ToastData> _activeToasts = [];
  static final GlobalKey<_ToastContainerState> _containerKey = GlobalKey<_ToastContainerState>();

  /// Shows a toast notification.
  static void show(
    BuildContext context, {
    required String message,
    String? title,
    ToastType type = ToastType.info,
    Duration duration = const Duration(milliseconds: 3500),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    final overlayState = Overlay.maybeOf(context, rootOverlay: true);
    if (overlayState == null) {
      // Fallback for environments without Overlay (e.g., bare widget tests)
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(message),
          duration: duration,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final toast = _ToastData(
      id: id,
      message: message,
      title: title,
      type: type,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );

    // Limit visible toasts to 3 max
    if (_activeToasts.length >= 3) {
      _activeToasts.removeAt(0);
    }
    _activeToasts.add(toast);

    if (_overlayEntry == null || _overlayEntry?.mounted != true) {
      if (_overlayEntry != null && _overlayEntry?.mounted != true) {
        _activeToasts.clear();
        _activeToasts.add(toast);
      }
      _overlayEntry = OverlayEntry(
        builder: (ctx) => _ToastContainer(
          key: _containerKey,
          onDismiss: (toastId) => _removeToast(toastId),
        ),
      );
      overlayState.insert(_overlayEntry!);
    } else {
      _containerKey.currentState?.update();
    }
  }

  /// Convenience shortcut for success toast.
  static void success(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(milliseconds: 3500),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    show(
      context,
      message: message,
      title: title,
      type: ToastType.success,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// Convenience shortcut for error toast.
  static void error(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(milliseconds: 4000),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    show(
      context,
      message: message,
      title: title,
      type: ToastType.error,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// Convenience shortcut for warning toast.
  static void warning(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(milliseconds: 3500),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    show(
      context,
      message: message,
      title: title,
      type: ToastType.warning,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// Convenience shortcut for info toast.
  static void info(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(milliseconds: 3500),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    show(
      context,
      message: message,
      title: title,
      type: ToastType.info,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// Removes a toast by ID and cleans up overlay when empty.
  static void _removeToast(String id) {
    _activeToasts.removeWhere((t) => t.id == id);
    if (_activeToasts.isEmpty) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    } else {
      _containerKey.currentState?.update();
    }
  }
}

/// Host widget that renders active toasts in an animated column.
class _ToastContainer extends StatefulWidget {
  final void Function(String id) onDismiss;

  const _ToastContainer({
    super.key,
    required this.onDismiss,
  });

  @override
  State<_ToastContainer> createState() => _ToastContainerState();
}

class _ToastContainerState extends State<_ToastContainer> {
  void update() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isDesktop = mediaQuery.size.width >= 600;

    return SafeArea(
      child: Align(
        alignment: isDesktop ? Alignment.topRight : Alignment.topCenter,
        child: Container(
          width: isDesktop ? 390 : double.infinity,
          margin: EdgeInsets.only(
            top: 16,
            right: isDesktop ? 20 : 16,
            left: isDesktop ? 0 : 16,
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  isDesktop ? CrossAxisAlignment.end : CrossAxisAlignment.stretch,
              children: SmartToast._activeToasts.map((toast) {
                return Padding(
                  key: ValueKey(toast.id),
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SmartToastCard(
                    toast: toast,
                    onDismiss: () => widget.onDismiss(toast.id),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

/// Individual Toast Card with animations, hover pause, and progress indicator.
class _SmartToastCard extends StatefulWidget {
  final _ToastData toast;
  final VoidCallback onDismiss;

  const _SmartToastCard({
    required this.toast,
    required this.onDismiss,
  });

  @override
  State<_SmartToastCard> createState() => _SmartToastCardState();
}

class _SmartToastCardState extends State<_SmartToastCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _scaleAnimation;
  Timer? _dismissTimer;
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutBack,
      ),
    );

    _animController.forward();
    _dismissTimer = Timer(widget.toast.duration, _dismiss);
  }

  void _dismiss() {
    if (_isExiting || !mounted) return;
    _isExiting = true;
    _dismissTimer?.cancel();
    _animController.reverse().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  void _handleMouseEnter(PointerEvent _) {
    _dismissTimer?.cancel();
  }

  void _handleMouseExit(PointerEvent _) {
    if (!_isExiting && mounted) {
      _dismissTimer = Timer(const Duration(milliseconds: 2000), _dismiss);
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  Color _getAccentColor(ToastType type) {
    switch (type) {
      case ToastType.success:
        return const Color(0xFF10B981);
      case ToastType.error:
        return const Color(0xFFEF4444);
      case ToastType.warning:
        return const Color(0xFFF59E0B);
      case ToastType.info:
        return const Color(0xFF3B82F6);
    }
  }

  IconData _getIcon(ToastType type) {
    switch (type) {
      case ToastType.success:
        return Icons.check_circle_rounded;
      case ToastType.error:
        return Icons.error_outline_rounded;
      case ToastType.warning:
        return Icons.warning_amber_rounded;
      case ToastType.info:
        return Icons.info_outline_rounded;
    }
  }

  String _getDefaultTitle(ToastType type, bool isEnglish) {
    switch (type) {
      case ToastType.success:
        return isEnglish ? 'Success' : 'Succès';
      case ToastType.error:
        return isEnglish ? 'Error' : 'Erreur';
      case ToastType.warning:
        return isEnglish ? 'Warning' : 'Attention';
      case ToastType.info:
        return isEnglish ? 'Information' : 'Information';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final locale = Localizations.maybeLocaleOf(context)?.languageCode ?? 'fr';
    final isEnglish = locale.startsWith('en');

    final accent = _getAccentColor(widget.toast.type);
    final icon = _getIcon(widget.toast.type);
    final displayTitle = widget.toast.title ?? _getDefaultTitle(widget.toast.type, isEnglish);

    final cardBg = isDark
        ? const Color(0xFF131A2A).withValues(alpha: 0.94)
        : Colors.white.withValues(alpha: 0.96);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    return MouseRegion(
      onEnter: _handleMouseEnter,
      onExit: _handleMouseExit,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: accent.withValues(alpha: isDark ? 0.38 : 0.22),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: isDark ? 0.18 : 0.10),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left glowing icon badge
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: accent.withValues(
                                    alpha: isDark ? 0.20 : 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: accent.withValues(
                                      alpha: isDark ? 0.35 : 0.20),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                icon,
                                color: accent,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Main textual content
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 1),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      displayTitle,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: textPrimary,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      widget.toast.message,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w400,
                                        color: textSecondary,
                                        height: 1.35,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (widget.toast.actionLabel != null &&
                                        widget.toast.onAction != null) ...[
                                      const SizedBox(height: 8),
                                      InkWell(
                                        onTap: () {
                                          _dismiss();
                                          widget.toast.onAction!();
                                        },
                                        borderRadius: BorderRadius.circular(6),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          child: Text(
                                            widget.toast.actionLabel!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: accent,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(width: 6),

                            // Dismiss close button
                            InkWell(
                              onTap: _dismiss,
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: isDark
                                      ? const Color(0xFF64748B)
                                      : const Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Subtle gradient accent indicator at bottom
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(16),
                        ),
                        child: SizedBox(
                          height: 2.5,
                          width: double.infinity,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  accent.withValues(alpha: 0.35),
                                  accent,
                                  accent.withValues(alpha: 0.55),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
