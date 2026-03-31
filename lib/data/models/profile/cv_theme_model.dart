import 'package:flutter/material.dart';

class CvThemeModel {
  final Color primaryColor;
  final Color accentColor;
  final Color headerBgColor;
  final Color headerTextColor;
  final Color bodyTextColor;
  final Color sectionTitleColor;
  final Color dividerColor;
  final Color skillBarColor;
  final Color bgColor;

  const CvThemeModel({
    required this.primaryColor,
    required this.accentColor,
    required this.headerBgColor,
    required this.headerTextColor,
    required this.bodyTextColor,
    required this.sectionTitleColor,
    required this.dividerColor,
    required this.skillBarColor,
    required this.bgColor,
  });

  CvThemeModel copyWith({
    Color? primaryColor,
    Color? accentColor,
    Color? headerBgColor,
    Color? headerTextColor,
    Color? bodyTextColor,
    Color? sectionTitleColor,
    Color? dividerColor,
    Color? skillBarColor,
    Color? bgColor,
  }) {
    return CvThemeModel(
      primaryColor: primaryColor ?? this.primaryColor,
      accentColor: accentColor ?? this.accentColor,
      headerBgColor: headerBgColor ?? this.headerBgColor,
      headerTextColor: headerTextColor ?? this.headerTextColor,
      bodyTextColor: bodyTextColor ?? this.bodyTextColor,
      sectionTitleColor: sectionTitleColor ?? this.sectionTitleColor,
      dividerColor: dividerColor ?? this.dividerColor,
      skillBarColor: skillBarColor ?? this.skillBarColor,
      bgColor: bgColor ?? this.bgColor,
    );
  }

  Map<String, int> toJson() => {
        'primaryColor': primaryColor.toARGB32(),
        'accentColor': accentColor.toARGB32(),
        'headerBgColor': headerBgColor.toARGB32(),
        'headerTextColor': headerTextColor.toARGB32(),
        'bodyTextColor': bodyTextColor.toARGB32(),
        'sectionTitleColor': sectionTitleColor.toARGB32(),
        'dividerColor': dividerColor.toARGB32(),
        'skillBarColor': skillBarColor.toARGB32(),
        'bgColor': bgColor.toARGB32(),
      };

  factory CvThemeModel.fromJson(Map<String, dynamic> json) {
    return CvThemeModel(
      primaryColor: Color(json['primaryColor'] as int),
      accentColor: Color(json['accentColor'] as int),
      headerBgColor: Color(json['headerBgColor'] as int),
      headerTextColor: Color(json['headerTextColor'] as int),
      bodyTextColor: Color(json['bodyTextColor'] as int),
      sectionTitleColor: Color(json['sectionTitleColor'] as int),
      dividerColor: Color(json['dividerColor'] as int),
      skillBarColor: Color(json['skillBarColor'] as int),
      bgColor: Color(json['bgColor'] as int),
    );
  }

  /// Preset themes (Canva-style)
  static const CvThemeModel classic = CvThemeModel(
    primaryColor: Color(0xFF1E293B),
    accentColor: Color(0xFFF26E22),
    headerBgColor: Color(0xFF1E293B),
    headerTextColor: Colors.white,
    bodyTextColor: Color(0xFF374151),
    sectionTitleColor: Color(0xFF1E293B),
    dividerColor: Color(0xFFE2E8F0),
    skillBarColor: Color(0xFFF26E22),
    bgColor: Colors.white,
  );

  static const CvThemeModel ocean = CvThemeModel(
    primaryColor: Color(0xFF0F766E),
    accentColor: Color(0xFF14B8A6),
    headerBgColor: Color(0xFF0F766E),
    headerTextColor: Colors.white,
    bodyTextColor: Color(0xFF374151),
    sectionTitleColor: Color(0xFF0F766E),
    dividerColor: Color(0xFFCCFBF1),
    skillBarColor: Color(0xFF14B8A6),
    bgColor: Colors.white,
  );

  static const CvThemeModel royal = CvThemeModel(
    primaryColor: Color(0xFF6D28D9),
    accentColor: Color(0xFF8B5CF6),
    headerBgColor: Color(0xFF6D28D9),
    headerTextColor: Colors.white,
    bodyTextColor: Color(0xFF374151),
    sectionTitleColor: Color(0xFF6D28D9),
    dividerColor: Color(0xFFEDE9FE),
    skillBarColor: Color(0xFF8B5CF6),
    bgColor: Colors.white,
  );

  static const CvThemeModel crimson = CvThemeModel(
    primaryColor: Color(0xFFDC2626),
    accentColor: Color(0xFFF87171),
    headerBgColor: Color(0xFFDC2626),
    headerTextColor: Colors.white,
    bodyTextColor: Color(0xFF374151),
    sectionTitleColor: Color(0xFFDC2626),
    dividerColor: Color(0xFFFEE2E2),
    skillBarColor: Color(0xFFF87171),
    bgColor: Colors.white,
  );

  static const CvThemeModel forest = CvThemeModel(
    primaryColor: Color(0xFF166534),
    accentColor: Color(0xFF22C55E),
    headerBgColor: Color(0xFF166534),
    headerTextColor: Colors.white,
    bodyTextColor: Color(0xFF374151),
    sectionTitleColor: Color(0xFF166534),
    dividerColor: Color(0xFFDCFCE7),
    skillBarColor: Color(0xFF22C55E),
    bgColor: Colors.white,
  );

  static const CvThemeModel midnight = CvThemeModel(
    primaryColor: Color(0xFF1E3A5F),
    accentColor: Color(0xFF3B82F6),
    headerBgColor: Color(0xFF1E3A5F),
    headerTextColor: Colors.white,
    bodyTextColor: Color(0xFF374151),
    sectionTitleColor: Color(0xFF1E3A5F),
    dividerColor: Color(0xFFDBEAFE),
    skillBarColor: Color(0xFF3B82F6),
    bgColor: Colors.white,
  );

  static const CvThemeModel rose = CvThemeModel(
    primaryColor: Color(0xFFBE185D),
    accentColor: Color(0xFFF472B6),
    headerBgColor: Color(0xFFBE185D),
    headerTextColor: Colors.white,
    bodyTextColor: Color(0xFF374151),
    sectionTitleColor: Color(0xFFBE185D),
    dividerColor: Color(0xFFFCE7F3),
    skillBarColor: Color(0xFFF472B6),
    bgColor: Colors.white,
  );

  static const CvThemeModel slate = CvThemeModel(
    primaryColor: Color(0xFF475569),
    accentColor: Color(0xFF94A3B8),
    headerBgColor: Color(0xFF475569),
    headerTextColor: Colors.white,
    bodyTextColor: Color(0xFF374151),
    sectionTitleColor: Color(0xFF475569),
    dividerColor: Color(0xFFE2E8F0),
    skillBarColor: Color(0xFF94A3B8),
    bgColor: Colors.white,
  );

  static const List<CvThemePreset> presets = [
    CvThemePreset(name: 'Classique', theme: classic, icon: '🏛️'),
    CvThemePreset(name: 'Océan', theme: ocean, icon: '🌊'),
    CvThemePreset(name: 'Royal', theme: royal, icon: '👑'),
    CvThemePreset(name: 'Crimson', theme: crimson, icon: '🔥'),
    CvThemePreset(name: 'Forêt', theme: forest, icon: '🌲'),
    CvThemePreset(name: 'Nuit', theme: midnight, icon: '🌙'),
    CvThemePreset(name: 'Rose', theme: rose, icon: '🌸'),
    CvThemePreset(name: 'Ardoise', theme: slate, icon: '🪨'),
  ];
}

class CvThemePreset {
  final String name;
  final CvThemeModel theme;
  final String icon;

  const CvThemePreset({
    required this.name,
    required this.theme,
    required this.icon,
  });
}
