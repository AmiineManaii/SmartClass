import 'package:flutter/material.dart';
import '../typography/typography_config.dart';
import '../constants/app_constants.dart';

class AppTheme {
  static const Color primary = Color(0xFF122675);
  static const Color primaryContainer = Color(0xFF2D3E8C);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF9EAEFF);
  
  static const Color secondary = Color(0xFF4056B9);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFF8197FF);
  static const Color onSecondaryContainer = Color(0xFF09288E);
  
  static const Color tertiary = Color(0xFF003627);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFF004F3B);
  static const Color onTertiaryContainer = Color(0xFF4EC69F);
  
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);
  
  static const Color surface = Color(0xFFFAF8FF);
  static const Color onSurface = Color(0xFF151B2F);
  static const Color surfaceContainerHighest = Color(0xFFDCE1FE);
  static const Color onSurfaceVariant = Color(0xFF454651);
  
  static const Color outline = Color(0xFF757682);
  static const Color outlineVariant = Color(0xFFC6C5D3);
  
  static const Color surfaceTint = Color(0xFF4858A8);
  
  static const Color inverseSurface = Color(0xFF2A3045);
  static const Color inversePrimary = Color(0xFFB9C3FF);
  
  static const Color shadow = Color(0xFF1D2338);
  
  static const Color primaryFixed = Color(0xFFDEE1FF);
  static const Color primaryFixedDim = Color(0xFFB9C3FF);
  static const Color onPrimaryFixed = Color(0xFF001258);
  static const Color onPrimaryFixedVariant = Color(0xFF2F408E);

  static const Color secondaryFixed = Color(0xFFDDE1FF);
  static const Color secondaryFixedDim = Color(0xFFB9C3FF);
  static const Color onSecondaryFixed = Color(0xFF001257);
  static const Color onSecondaryFixedVariant = Color(0xFF243DA0);

  static const Color tertiaryFixed = Color(0xFF83F8CD);
  static const Color tertiaryFixedDim = Color(0xFF65DBB2);
  static const Color onTertiaryFixed = Color(0xFF002116);
  static const Color onTertiaryFixedVariant = Color(0xFF00513C);

  static const Color success = Color(0xFF0F9D78);
  static const Color successContainer = Color(0xFF83F8CD);
  static const Color onSuccessContainer = Color(0xFF002116);
  
  static const Color warning = Color(0xFFF5A623);
  static const Color warningContainer = Color(0xFFFFF4E0);
  static const Color onWarningContainer = Color(0xFF8A6200);
  
  static const List<Color> primaryGradient = [primary, primaryContainer];
  
  static ColorScheme get lightColorScheme => const ColorScheme.light(
    primary: primary,
    primaryContainer: primaryContainer,
    onPrimary: onPrimary,
    onPrimaryContainer: onPrimaryContainer,
    primaryFixed: primaryFixed,
    primaryFixedDim: primaryFixedDim,
    onPrimaryFixed: onPrimaryFixed,
    onPrimaryFixedVariant: onPrimaryFixedVariant,
    secondary: secondary,
    onSecondary: onSecondary,
    secondaryContainer: secondaryContainer,
    onSecondaryContainer: onSecondaryContainer,
    secondaryFixed: secondaryFixed,
    secondaryFixedDim: secondaryFixedDim,
    onSecondaryFixed: onSecondaryFixed,
    onSecondaryFixedVariant: onSecondaryFixedVariant,
    tertiary: tertiary,
    onTertiary: onTertiary,
    tertiaryContainer: tertiaryContainer,
    onTertiaryContainer: onTertiaryContainer,
    tertiaryFixed: tertiaryFixed,
    tertiaryFixedDim: tertiaryFixedDim,
    onTertiaryFixed: onTertiaryFixed,
    onTertiaryFixedVariant: onTertiaryFixedVariant,
    error: error,
    onError: onError,
    errorContainer: errorContainer,
    onErrorContainer: onErrorContainer,
    surface: surface,
    onSurface: onSurface,
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF3F2FF),
    surfaceContainer: Color(0xFFEBEDFF),
    surfaceContainerHigh: Color(0xFFE3E7FF),
    surfaceContainerHighest: surfaceContainerHighest,
    onSurfaceVariant: onSurfaceVariant,
    outline: outline,
    outlineVariant: outlineVariant,
    surfaceTint: surfaceTint,
    inverseSurface: inverseSurface,
    onInverseSurface: Color(0xFFEFF0FF),
    inversePrimary: inversePrimary,
    shadow: shadow,
  );
  
  static ColorScheme get darkColorScheme => const ColorScheme.dark(
    primary: inversePrimary,
    primaryContainer: primaryContainer,
    onPrimary: primary,
    onPrimaryContainer: primaryFixed,
    primaryFixed: primaryFixed,
    primaryFixedDim: primaryFixedDim,
    onPrimaryFixed: onPrimaryFixed,
    onPrimaryFixedVariant: onPrimaryFixedVariant,
    secondary: secondaryContainer,
    onSecondary: Color(0xFF001257),
    secondaryContainer: Color(0xFF243DA0),
    onSecondaryContainer: secondaryFixed,
    secondaryFixed: secondaryFixed,
    secondaryFixedDim: secondaryFixedDim,
    onSecondaryFixed: onSecondaryFixed,
    onSecondaryFixedVariant: onSecondaryFixedVariant,
    tertiary: tertiaryFixedDim,
    onTertiary: tertiary,
    tertiaryContainer: tertiaryContainer,
    onTertiaryContainer: tertiaryFixed,
    tertiaryFixed: tertiaryFixed,
    tertiaryFixedDim: tertiaryFixedDim,
    onTertiaryFixed: onTertiaryFixed,
    onTertiaryFixedVariant: onTertiaryFixedVariant,
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF151B2F),
    onSurface: Color(0xFFEFF0FF),
    surfaceContainerLowest: Color(0xFF101524),
    surfaceContainerLow: Color(0xFF1A2035),
    surfaceContainer: Color(0xFF202640),
    surfaceContainerHigh: Color(0xFF262D4A),
    surfaceContainerHighest: Color(0xFF353D5F),
    onSurfaceVariant: Color(0xFFC6C5D3),
    outline: outlineVariant,
    outlineVariant: Color(0xFF454651),
    surfaceTint: surfaceTint,
    inverseSurface: surface,
    onInverseSurface: onSurface,
    inversePrimary: primary,
    shadow: Color(0xFF000000),
  );

  static ThemeData getLightTheme(AppTextStyles textStyles) => _buildTheme(lightColorScheme, textStyles, Brightness.light);
  
  static ThemeData getDarkTheme(AppTextStyles textStyles) => _buildTheme(darkColorScheme, textStyles, Brightness.dark);
  
  static ThemeData _buildTheme(ColorScheme colorScheme, AppTextStyles textStyles, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: brightness,
      fontFamily: textStyles.config.fontFamily.fontFamily,
      
      textTheme: TextTheme(
        displayLarge: textStyles.displayLarge.copyWith(color: colorScheme.onSurface),
        displayMedium: textStyles.headlineLarge.copyWith(color: colorScheme.onSurface),
        displaySmall: textStyles.headlineMedium.copyWith(color: colorScheme.onSurface),
        headlineLarge: textStyles.headlineLarge.copyWith(color: colorScheme.onSurface),
        headlineMedium: textStyles.headlineMedium.copyWith(color: colorScheme.onSurface),
        headlineSmall: textStyles.headlineSmall.copyWith(color: colorScheme.onSurface),
        titleLarge: textStyles.headlineSmall.copyWith(color: colorScheme.onSurface),
        titleMedium: textStyles.labelLarge.copyWith(color: colorScheme.onSurface),
        titleSmall: textStyles.labelMedium.copyWith(color: colorScheme.onSurface),
        bodyLarge: textStyles.bodyLarge.copyWith(color: colorScheme.onSurface),
        bodyMedium: textStyles.bodyMedium.copyWith(color: colorScheme.onSurface),
        bodySmall: textStyles.bodySmall.copyWith(color: colorScheme.onSurfaceVariant),
        labelLarge: textStyles.labelLarge.copyWith(color: colorScheme.onSurface),
        labelMedium: textStyles.labelMedium.copyWith(color: colorScheme.onSurface),
        labelSmall: textStyles.labelSmall.copyWith(color: colorScheme.onSurfaceVariant),
      ),
      
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: textStyles.headlineSmall.copyWith(color: colorScheme.onSurface),
        toolbarHeight: 56,
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
          ),
          textStyle: textStyles.button,
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith<Color?>(
            (states) => states.contains(WidgetState.pressed)
                ? colorScheme.primary.withValues(alpha: 0.9)
                : null,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary, width: 1.5),
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
          ),
          textStyle: textStyles.button,
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
          ),
          textStyle: textStyles.labelMedium,
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.inputBorderRadius),
          borderSide: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.inputBorderRadius),
          borderSide: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.inputBorderRadius),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.inputBorderRadius),
          borderSide: BorderSide(color: colorScheme.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.inputBorderRadius),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.inputBorderRadius),
          borderSide: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5), width: 1),
        ),
        labelStyle: textStyles.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant),
        hintStyle: textStyles.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
        errorStyle: textStyles.bodySmall.copyWith(color: colorScheme.error),
        floatingLabelStyle: textStyles.labelSmall.copyWith(color: colorScheme.primary),
        prefixIconColor: colorScheme.onSurfaceVariant,
        suffixIconColor: colorScheme.onSurfaceVariant,
      ),
      
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        shadowColor: isDark ? colorScheme.shadow.withValues(alpha: 0.3) : colorScheme.shadow.withValues(alpha: 0.04),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          side: BorderSide(
            color: isDark 
                ? colorScheme.outlineVariant.withValues(alpha: 0.2)
                : colorScheme.primary.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
        margin: EdgeInsets.zero,
      ),
      
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.primaryContainer,
        disabledColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        labelStyle: textStyles.chip.copyWith(color: colorScheme.onSurfaceVariant),
        secondaryLabelStyle: textStyles.chip.copyWith(color: colorScheme.onPrimaryContainer),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.badgeBorderRadius),
          side: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
        side: BorderSide(color: colorScheme.outlineVariant, width: 1),
        brightness: brightness,
        elevation: 0,
        pressElevation: 0,
      ),
      
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.modalBorderRadius),
        ),
        titleTextStyle: textStyles.headlineSmall.copyWith(color: colorScheme.onSurface),
        contentTextStyle: textStyles.bodyMedium.copyWith(color: colorScheme.onSurface),
      ),
      
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.modalBorderRadius)),
        ),
        modalBackgroundColor: colorScheme.surface,
        dragHandleColor: colorScheme.onSurfaceVariant,
        showDragHandle: true,
      ),
      
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: colorScheme.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
            size: 24,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
          (states) => textStyles.labelSmall.copyWith(
            color: states.contains(WidgetState.selected)
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      
      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicatorColor: colorScheme.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: textStyles.labelMedium,
        unselectedLabelStyle: textStyles.labelMedium,
        dividerColor: Colors.transparent,
        overlayColor: WidgetStateProperty.resolveWith<Color?>(
          (states) => states.contains(WidgetState.pressed)
              ? colorScheme.primary.withValues(alpha: 0.1)
              : null,
        ),
      ),
      
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 0.5,
        space: 1,
        indent: 56,
      ),
      
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        ),
        tileColor: Colors.transparent,
        selectedTileColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
        iconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
        titleTextStyle: textStyles.bodyLarge.copyWith(color: colorScheme.onSurface),
        subtitleTextStyle: textStyles.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant),
        leadingAndTrailingTextStyle: textStyles.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant),
      ),
      
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(colorScheme.surface),
          surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
          elevation: WidgetStatePropertyAll(2),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
              side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
            ),
          ),
        ),
      ),
      
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        focusElevation: 4,
        hoverElevation: 4,
        highlightElevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
        ),
      ),
      
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
        circularTrackColor: colorScheme.surfaceContainerHighest,
      ),
      
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.surfaceContainerHighest,
        thumbColor: colorScheme.primary,
        overlayColor: colorScheme.primary.withValues(alpha: 0.12),
        valueIndicatorColor: colorScheme.primary,
        valueIndicatorTextStyle: textStyles.labelSmall.copyWith(color: colorScheme.onPrimary),
      ),
      
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>(
          (states) => states.contains(WidgetState.selected)
              ? colorScheme.primary
              : colorScheme.outline,
        ),
        trackColor: WidgetStateProperty.resolveWith<Color?>(
          (states) => states.contains(WidgetState.selected)
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
        ),
        trackOutlineColor: WidgetStatePropertyAll(colorScheme.outlineVariant),
      ),
      
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color?>(
          (states) => states.contains(WidgetState.selected)
              ? colorScheme.primary
              : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(colorScheme.onPrimary),
        side: BorderSide(color: colorScheme.outline, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        visualDensity: VisualDensity.compact,
      ),
      
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color?>(
          (states) => states.contains(WidgetState.selected)
              ? colorScheme.primary
              : colorScheme.outline,
        ),
        visualDensity: VisualDensity.compact,
      ),
      
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: textStyles.bodySmall.copyWith(color: colorScheme.onInverseSurface),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        preferBelow: true,
        verticalOffset: 8,
      ),
      
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: textStyles.bodyMedium.copyWith(color: colorScheme.onInverseSurface),
        actionTextColor: colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        ),
        elevation: 4,
      ),
      
      extensions: <ThemeExtension<dynamic>>[
        _CustomThemeExtension(
          successColor: success,
          successContainer: successContainer,
          onSuccessContainer: onSuccessContainer,
          warningColor: warning,
          warningContainer: warningContainer,
          onWarningContainer: onWarningContainer,
          cardShadowColor: isDark 
              ? shadow.withValues(alpha: 0.3) 
              : shadow.withValues(alpha: 0.04),
          cardBorderColor: isDark
              ? outlineVariant.withValues(alpha: 0.2)
              : primary.withValues(alpha: 0.06),
          level1Shadow: [
            BoxShadow(
              color: isDark 
                  ? shadow.withValues(alpha: 0.3)
                  : shadow.withValues(alpha: 0.04),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
            BoxShadow(
              color: isDark 
                  ? shadow.withValues(alpha: 0.2)
                  : shadow.withValues(alpha: 0.02),
              offset: const Offset(0, 1),
              blurRadius: 2,
            ),
          ],
          level2Shadow: [
            BoxShadow(
              color: isDark
                  ? shadow.withValues(alpha: 0.4)
                  : shadow.withValues(alpha: 0.08),
              offset: const Offset(0, 10),
              blurRadius: 25,
              spreadRadius: -5,
            ),
            BoxShadow(
              color: isDark
                  ? shadow.withValues(alpha: 0.2)
                  : shadow.withValues(alpha: 0.03),
              offset: const Offset(0, 4),
              blurRadius: 6,
              spreadRadius: -2,
            ),
          ],
          level3Shadow: [
            BoxShadow(
              color: shadow.withValues(alpha: 0.32),
              offset: const Offset(0, 0),
              blurRadius: 20,
            ),
          ],
        ),
      ],
    );
  }
}

class _CustomThemeExtension extends ThemeExtension<_CustomThemeExtension> {
  final Color successColor;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warningColor;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color cardShadowColor;
  final Color cardBorderColor;
  final List<BoxShadow> level1Shadow;
  final List<BoxShadow> level2Shadow;
  final List<BoxShadow> level3Shadow;

  const _CustomThemeExtension({
    required this.successColor,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warningColor,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.cardShadowColor,
    required this.cardBorderColor,
    required this.level1Shadow,
    required this.level2Shadow,
    required this.level3Shadow,
  });

  @override
  _CustomThemeExtension copyWith({
    Color? successColor,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warningColor,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? cardShadowColor,
    Color? cardBorderColor,
    List<BoxShadow>? level1Shadow,
    List<BoxShadow>? level2Shadow,
    List<BoxShadow>? level3Shadow,
  }) {
    return _CustomThemeExtension(
      successColor: successColor ?? this.successColor,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warningColor: warningColor ?? this.warningColor,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      cardShadowColor: cardShadowColor ?? this.cardShadowColor,
      cardBorderColor: cardBorderColor ?? this.cardBorderColor,
      level1Shadow: level1Shadow ?? this.level1Shadow,
      level2Shadow: level2Shadow ?? this.level2Shadow,
      level3Shadow: level3Shadow ?? this.level3Shadow,
    );
  }

  @override
  _CustomThemeExtension lerp(ThemeExtension<_CustomThemeExtension>? other, double t) {
    if (other is! _CustomThemeExtension) return this;
    return _CustomThemeExtension(
      successColor: Color.lerp(successColor, other.successColor, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      onSuccessContainer: Color.lerp(onSuccessContainer, other.onSuccessContainer, t)!,
      warningColor: Color.lerp(warningColor, other.warningColor, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      onWarningContainer: Color.lerp(onWarningContainer, other.onWarningContainer, t)!,
      cardShadowColor: Color.lerp(cardShadowColor, other.cardShadowColor, t)!,
      cardBorderColor: Color.lerp(cardBorderColor, other.cardBorderColor, t)!,
      level1Shadow: level1Shadow,
      level2Shadow: level2Shadow,
      level3Shadow: level3Shadow,
    );
  }
}

extension CustomThemeExtension on ThemeData {
  _CustomThemeExtension get custom => extension<_CustomThemeExtension>()!;
  
  Color get successColor => custom.successColor;
  Color get successContainer => custom.successContainer;
  Color get onSuccessContainer => custom.onSuccessContainer;
  Color get warningColor => custom.warningColor;
  Color get warningContainer => custom.warningContainer;
  Color get onWarningContainer => custom.onWarningContainer;
  Color get cardShadowColor => custom.cardShadowColor;
  Color get cardBorderColor => custom.cardBorderColor;
  List<BoxShadow> get level1Shadow => custom.level1Shadow;
  List<BoxShadow> get level2Shadow => custom.level2Shadow;
  List<BoxShadow> get level3Shadow => custom.level3Shadow;
}