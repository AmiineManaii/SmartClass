import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum FontFamilyOption {
  inter('Inter', 'Inter'),
  roboto('Roboto', 'Roboto'),
  openSans('Open Sans', 'Open Sans'),
  system('Système', 'System');

  const FontFamilyOption(this.displayName, this.fontFamily);
  
  final String displayName;
  final String fontFamily;
}

enum FontSizeOption {
  small('Petit', 0.85),
  medium('Moyen', 1.0),
  large('Grand', 1.15),
  extraLarge('Très grand', 1.3);

  const FontSizeOption(this.displayName, this.scaleFactor);
  
  final String displayName;
  final double scaleFactor;
}

class TypographyConfig {
  final FontFamilyOption fontFamily;
  final FontSizeOption fontSize;
  final double textScaleFactor;

  const TypographyConfig({
    this.fontFamily = FontFamilyOption.inter,
    this.fontSize = FontSizeOption.medium,
    this.textScaleFactor = 1.0,
  });

  TypographyConfig copyWith({
    FontFamilyOption? fontFamily,
    FontSizeOption? fontSize,
    double? textScaleFactor,
  }) {
    return TypographyConfig(
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      textScaleFactor: textScaleFactor ?? this.textScaleFactor,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TypographyConfig &&
          runtimeType == other.runtimeType &&
          fontFamily == other.fontFamily &&
          fontSize == other.fontSize &&
          textScaleFactor == other.textScaleFactor;

  @override
  int get hashCode => Object.hash(fontFamily, fontSize, textScaleFactor);
}

class AppTextStyles {
  final TypographyConfig config;
  
  const AppTextStyles(this.config);
  
  double get _baseScale => config.fontSize.scaleFactor * config.textScaleFactor;
  
  String get _fontFamily => config.fontFamily.fontFamily;
  
  TextStyle get displayLarge => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 34 * _baseScale,
    fontWeight: FontWeight.w700,
    height: 41 / 34,
    letterSpacing: -0.022,
  );
  
  TextStyle get headlineLarge => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28 * _baseScale,
    fontWeight: FontWeight.w600,
    height: 34 / 28,
    letterSpacing: -0.019,
  );
  
  TextStyle get headlineMedium => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 22 * _baseScale,
    fontWeight: FontWeight.w600,
    height: 28 / 22,
    letterSpacing: -0.015,
  );
  
  TextStyle get headlineSmall => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20 * _baseScale,
    fontWeight: FontWeight.w600,
    height: 25 / 20,
    letterSpacing: -0.012,
  );
  
  TextStyle get bodyLarge => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 17 * _baseScale,
    fontWeight: FontWeight.w400,
    height: 22 / 17,
    letterSpacing: -0.011,
  );
  
  TextStyle get bodyMedium => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 15 * _baseScale,
    fontWeight: FontWeight.w400,
    height: 20 / 15,
    letterSpacing: -0.008,
  );
  
  TextStyle get bodySmall => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13 * _baseScale,
    fontWeight: FontWeight.w400,
    height: 18 / 13,
    letterSpacing: -0.003,
  );
  
  TextStyle get labelLarge => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 17 * _baseScale,
    fontWeight: FontWeight.w600,
    height: 22 / 17,
    letterSpacing: -0.011,
  );
  
  TextStyle get labelMedium => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 15 * _baseScale,
    fontWeight: FontWeight.w600,
    height: 20 / 15,
    letterSpacing: -0.008,
  );
  
  TextStyle get labelSmall => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12 * _baseScale,
    fontWeight: FontWeight.w600,
    height: 16 / 12,
    letterSpacing: 0.002,
  );
  
  TextStyle get caption => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11 * _baseScale,
    fontWeight: FontWeight.w500,
    height: 13 / 11,
    letterSpacing: 0.006,
  );
  
  TextStyle get button => labelMedium.copyWith(
    letterSpacing: 0.008,
  );
  
  TextStyle get input => bodyMedium;
  
  TextStyle get chip => labelSmall;
  
  TextStyle get overline => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 10 * _baseScale,
    fontWeight: FontWeight.w400,
    height: 14 / 10,
    letterSpacing: 0.01,
  );
}

class TypographyRepository {
  static const String _keyFontFamily = 'typography_font_family';
  static const String _keyFontSize = 'typography_font_size';
  static const String _keyTextScale = 'typography_text_scale';
  
  Future<TypographyConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    
    final fontFamilyIndex = prefs.getInt(_keyFontFamily) ?? 0;
    final fontSizeIndex = prefs.getInt(_keyFontSize) ?? 1;
    final textScale = prefs.getDouble(_keyTextScale) ?? 1.0;
    
    return TypographyConfig(
      fontFamily: FontFamilyOption.values[fontFamilyIndex.clamp(0, FontFamilyOption.values.length - 1)],
      fontSize: FontSizeOption.values[fontSizeIndex.clamp(0, FontSizeOption.values.length - 1)],
      textScaleFactor: textScale.clamp(0.85, 1.5),
    );
  }
  
  Future<void> save(TypographyConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyFontFamily, config.fontFamily.index);
    await prefs.setInt(_keyFontSize, config.fontSize.index);
    await prefs.setDouble(_keyTextScale, config.textScaleFactor);
  }
  
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFontFamily);
    await prefs.remove(_keyFontSize);
    await prefs.remove(_keyTextScale);
  }
}