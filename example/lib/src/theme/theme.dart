import "package:flutter/material.dart";

class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  static MaterialScheme lightScheme() {
    return const MaterialScheme(
      brightness: Brightness.light,
      primary: Color(4278190080),
      surfaceTint: Color(4284374622),
      onPrimary: Color(4294967295),
      primaryContainer: Color(4280690214),
      onPrimaryContainer: Color(4289835441),
      secondary: Color(4284374622),
      onSecondary: Color(4294967295),
      secondaryContainer: Color(4293322470),
      onSecondaryContainer: Color(4283058762),
      tertiary: Color(4278190080),
      onTertiary: Color(4294967295),
      tertiaryContainer: Color(4280690214),
      onTertiaryContainer: Color(4289835441),
      error: Color(4290386458),
      onError: Color(4294967295),
      errorContainer: Color(4294957782),
      onErrorContainer: Color(4282449922),
      background: Color(4294572537),
      onBackground: Color(4279966491),
      surface: Color(4294572537),
      onSurface: Color(4279966491),
      surfaceVariant: Color(4293648609),
      onSurfaceVariant: Color(4283188550),
      outline: Color(4286477686),
      outlineVariant: Color(4291806405),
      shadow: Color(4278190080),
      scrim: Color(4278190080),
      inverseSurface: Color(4281348144),
      inverseOnSurface: Color(4294046193),
      inversePrimary: Color(4291217094),
      primaryFixed: Color(4293059298),
      onPrimaryFixed: Color(4279966491),
      primaryFixedDim: Color(4291217094),
      onPrimaryFixedVariant: Color(4282861383),
      secondaryFixed: Color(4293059298),
      onSecondaryFixed: Color(4279966491),
      secondaryFixedDim: Color(4291217094),
      onSecondaryFixedVariant: Color(4282861383),
      tertiaryFixed: Color(4293059298),
      onTertiaryFixed: Color(4279966491),
      tertiaryFixedDim: Color(4291217094),
      onTertiaryFixedVariant: Color(4282861383),
      surfaceDim: Color(4292532954),
      surfaceBright: Color(4294572537),
      surfaceContainerLowest: Color(4294967295),
      surfaceContainerLow: Color(4294177779),
      surfaceContainer: Color(4293848814),
      surfaceContainerHigh: Color(4293454056),
      surfaceContainerHighest: Color(4293059298),
    );
  }

  ThemeData light() {
    return theme(lightScheme().toColorScheme());
  }

  static MaterialScheme lightMediumContrastScheme() {
    return const MaterialScheme(
      brightness: Brightness.light,
      primary: Color(4278190080),
      surfaceTint: Color(4284374622),
      onPrimary: Color(4294967295),
      primaryContainer: Color(4280690214),
      onPrimaryContainer: Color(4292664540),
      secondary: Color(4282598211),
      onSecondary: Color(4294967295),
      secondaryContainer: Color(4285822068),
      onSecondaryContainer: Color(4294967295),
      tertiary: Color(4278190080),
      onTertiary: Color(4294967295),
      tertiaryContainer: Color(4280690214),
      onTertiaryContainer: Color(4292664540),
      error: Color(4287365129),
      onError: Color(4294967295),
      errorContainer: Color(4292490286),
      onErrorContainer: Color(4294967295),
      background: Color(4294572537),
      onBackground: Color(4279966491),
      surface: Color(4294572537),
      onSurface: Color(4279966491),
      surfaceVariant: Color(4293648609),
      onSurfaceVariant: Color(4282925378),
      outline: Color(4284833118),
      outlineVariant: Color(4286675066),
      shadow: Color(4278190080),
      scrim: Color(4278190080),
      inverseSurface: Color(4281348144),
      inverseOnSurface: Color(4294046193),
      inversePrimary: Color(4291217094),
      primaryFixed: Color(4285822068),
      onPrimaryFixed: Color(4294967295),
      primaryFixedDim: Color(4284243036),
      onPrimaryFixedVariant: Color(4294967295),
      secondaryFixed: Color(4285822068),
      onSecondaryFixed: Color(4294967295),
      secondaryFixedDim: Color(4284243036),
      onSecondaryFixedVariant: Color(4294967295),
      tertiaryFixed: Color(4285822068),
      onTertiaryFixed: Color(4294967295),
      tertiaryFixedDim: Color(4284243036),
      onTertiaryFixedVariant: Color(4294967295),
      surfaceDim: Color(4292532954),
      surfaceBright: Color(4294572537),
      surfaceContainerLowest: Color(4294967295),
      surfaceContainerLow: Color(4294177779),
      surfaceContainer: Color(4293848814),
      surfaceContainerHigh: Color(4293454056),
      surfaceContainerHighest: Color(4293059298),
    );
  }

  ThemeData lightMediumContrast() {
    return theme(lightMediumContrastScheme().toColorScheme());
  }

  static MaterialScheme lightHighContrastScheme() {
    return const MaterialScheme(
      brightness: Brightness.light,
      primary: Color(4278190080),
      surfaceTint: Color(4284374622),
      onPrimary: Color(4294967295),
      primaryContainer: Color(4280690214),
      onPrimaryContainer: Color(4294967295),
      secondary: Color(4280427042),
      onSecondary: Color(4294967295),
      secondaryContainer: Color(4282598211),
      onSecondaryContainer: Color(4294967295),
      tertiary: Color(4278190080),
      onTertiary: Color(4294967295),
      tertiaryContainer: Color(4280690214),
      onTertiaryContainer: Color(4294967295),
      error: Color(4283301890),
      onError: Color(4294967295),
      errorContainer: Color(4287365129),
      onErrorContainer: Color(4294967295),
      background: Color(4294572537),
      onBackground: Color(4279966491),
      surface: Color(4294572537),
      onSurface: Color(4278190080),
      surfaceVariant: Color(4293648609),
      onSurfaceVariant: Color(4280820260),
      outline: Color(4282925378),
      outlineVariant: Color(4282925378),
      shadow: Color(4278190080),
      scrim: Color(4278190080),
      inverseSurface: Color(4281348144),
      inverseOnSurface: Color(4294967295),
      inversePrimary: Color(4293717228),
      primaryFixed: Color(4282598211),
      onPrimaryFixed: Color(4294967295),
      primaryFixedDim: Color(4281150765),
      onPrimaryFixedVariant: Color(4294967295),
      secondaryFixed: Color(4282598211),
      onSecondaryFixed: Color(4294967295),
      secondaryFixedDim: Color(4281150765),
      onSecondaryFixedVariant: Color(4294967295),
      tertiaryFixed: Color(4282598211),
      onTertiaryFixed: Color(4294967295),
      tertiaryFixedDim: Color(4281150765),
      onTertiaryFixedVariant: Color(4294967295),
      surfaceDim: Color(4292532954),
      surfaceBright: Color(4294572537),
      surfaceContainerLowest: Color(4294967295),
      surfaceContainerLow: Color(4294177779),
      surfaceContainer: Color(4293848814),
      surfaceContainerHigh: Color(4293454056),
      surfaceContainerHighest: Color(4293059298),
    );
  }

  ThemeData lightHighContrast() {
    return theme(lightHighContrastScheme().toColorScheme());
  }

  static MaterialScheme darkScheme() {
    return const MaterialScheme(
      brightness: Brightness.dark,
      primary: Color(4291217094),
      surfaceTint: Color(4291217094),
      onPrimary: Color(4281348144),
      primaryContainer: Color(4278190080),
      onPrimaryContainer: Color(4288059030),
      secondary: Color(4291217094),
      onSecondary: Color(4281348144),
      secondaryContainer: Color(4282203453),
      onSecondaryContainer: Color(4291940817),
      tertiary: Color(4291217094),
      onTertiary: Color(4281348144),
      tertiaryContainer: Color(4278190080),
      onTertiaryContainer: Color(4288059030),
      error: Color(4294948011),
      onError: Color(4285071365),
      errorContainer: Color(4287823882),
      onErrorContainer: Color(4294957782),
      background: Color(4279440147),
      onBackground: Color(4293059298),
      surface: Color(4279440147),
      onSurface: Color(4293059298),
      surfaceVariant: Color(4283188550),
      onSurfaceVariant: Color(4291806405),
      outline: Color(4288188048),
      outlineVariant: Color(4283188550),
      shadow: Color(4278190080),
      scrim: Color(4278190080),
      inverseSurface: Color(4293059298),
      inverseOnSurface: Color(4281348144),
      inversePrimary: Color(4284374622),
      primaryFixed: Color(4293059298),
      onPrimaryFixed: Color(4279966491),
      primaryFixedDim: Color(4291217094),
      onPrimaryFixedVariant: Color(4282861383),
      secondaryFixed: Color(4293059298),
      onSecondaryFixed: Color(4279966491),
      secondaryFixedDim: Color(4291217094),
      onSecondaryFixedVariant: Color(4282861383),
      tertiaryFixed: Color(4293059298),
      onTertiaryFixed: Color(4279966491),
      tertiaryFixedDim: Color(4291217094),
      onTertiaryFixedVariant: Color(4282861383),
      surfaceDim: Color(4279440147),
      surfaceBright: Color(4281940281),
      surfaceContainerLowest: Color(4279111182),
      surfaceContainerLow: Color(4279966491),
      surfaceContainer: Color(4280229663),
      surfaceContainerHigh: Color(4280953386),
      surfaceContainerHighest: Color(4281677109),
    );
  }

  ThemeData dark() {
    return theme(darkScheme().toColorScheme());
  }

  static MaterialScheme darkMediumContrastScheme() {
    return const MaterialScheme(
      brightness: Brightness.dark,
      primary: Color(4291546059),
      surfaceTint: Color(4291217094),
      onPrimary: Color(4279637526),
      primaryContainer: Color(4287730065),
      onPrimaryContainer: Color(4278190080),
      secondary: Color(4291546059),
      onSecondary: Color(4279637526),
      secondaryContainer: Color(4287730065),
      onSecondaryContainer: Color(4278190080),
      tertiary: Color(4291546059),
      onTertiary: Color(4279637526),
      tertiaryContainer: Color(4287730065),
      onTertiaryContainer: Color(4278190080),
      error: Color(4294949553),
      onError: Color(4281794561),
      errorContainer: Color(4294923337),
      onErrorContainer: Color(4278190080),
      background: Color(4279440147),
      onBackground: Color(4293059298),
      surface: Color(4279440147),
      onSurface: Color(4294704123),
      surfaceVariant: Color(4283188550),
      onSurfaceVariant: Color(4292069577),
      outline: Color(4289372322),
      outlineVariant: Color(4287267202),
      shadow: Color(4278190080),
      scrim: Color(4278190080),
      inverseSurface: Color(4293059298),
      inverseOnSurface: Color(4280953386),
      inversePrimary: Color(4282927176),
      primaryFixed: Color(4293059298),
      onPrimaryFixed: Color(4279308561),
      primaryFixedDim: Color(4291217094),
      onPrimaryFixedVariant: Color(4281742902),
      secondaryFixed: Color(4293059298),
      onSecondaryFixed: Color(4279308561),
      secondaryFixedDim: Color(4291217094),
      onSecondaryFixedVariant: Color(4281742902),
      tertiaryFixed: Color(4293059298),
      onTertiaryFixed: Color(4279308561),
      tertiaryFixedDim: Color(4291217094),
      onTertiaryFixedVariant: Color(4281742902),
      surfaceDim: Color(4279440147),
      surfaceBright: Color(4281940281),
      surfaceContainerLowest: Color(4279111182),
      surfaceContainerLow: Color(4279966491),
      surfaceContainer: Color(4280229663),
      surfaceContainerHigh: Color(4280953386),
      surfaceContainerHighest: Color(4281677109),
    );
  }

  ThemeData darkMediumContrast() {
    return theme(darkMediumContrastScheme().toColorScheme());
  }

  static MaterialScheme darkHighContrastScheme() {
    return const MaterialScheme(
      brightness: Brightness.dark,
      primary: Color(4294704123),
      surfaceTint: Color(4291217094),
      onPrimary: Color(4278190080),
      primaryContainer: Color(4291546059),
      onPrimaryContainer: Color(4278190080),
      secondary: Color(4294704123),
      onSecondary: Color(4278190080),
      secondaryContainer: Color(4291546059),
      onSecondaryContainer: Color(4278190080),
      tertiary: Color(4294704123),
      onTertiary: Color(4278190080),
      tertiaryContainer: Color(4291546059),
      onTertiaryContainer: Color(4278190080),
      error: Color(4294965753),
      onError: Color(4278190080),
      errorContainer: Color(4294949553),
      onErrorContainer: Color(4278190080),
      background: Color(4279440147),
      onBackground: Color(4293059298),
      surface: Color(4279440147),
      onSurface: Color(4294967295),
      surfaceVariant: Color(4283188550),
      onSurfaceVariant: Color(4294965753),
      outline: Color(4292069577),
      outlineVariant: Color(4292069577),
      shadow: Color(4278190080),
      scrim: Color(4278190080),
      inverseSurface: Color(4293059298),
      inverseOnSurface: Color(4278190080),
      inversePrimary: Color(4280953386),
      primaryFixed: Color(4293388263),
      onPrimaryFixed: Color(4278190080),
      primaryFixedDim: Color(4291546059),
      onPrimaryFixedVariant: Color(4279637526),
      secondaryFixed: Color(4293388263),
      onSecondaryFixed: Color(4278190080),
      secondaryFixedDim: Color(4291546059),
      onSecondaryFixedVariant: Color(4279637526),
      tertiaryFixed: Color(4293388263),
      onTertiaryFixed: Color(4278190080),
      tertiaryFixedDim: Color(4291546059),
      onTertiaryFixedVariant: Color(4279637526),
      surfaceDim: Color(4279440147),
      surfaceBright: Color(4281940281),
      surfaceContainerLowest: Color(4279111182),
      surfaceContainerLow: Color(4279966491),
      surfaceContainer: Color(4280229663),
      surfaceContainerHigh: Color(4280953386),
      surfaceContainerHighest: Color(4281677109),
    );
  }

  ThemeData darkHighContrast() {
    return theme(darkHighContrastScheme().toColorScheme());
  }

  ThemeData theme(ColorScheme colorScheme) => ThemeData(
        useMaterial3: true,
        brightness: colorScheme.brightness,
        colorScheme: colorScheme,
        textTheme: textTheme.apply(
          bodyColor: colorScheme.onSurface,
          displayColor: colorScheme.onSurface,
        ),
        scaffoldBackgroundColor: colorScheme.background,
        canvasColor: colorScheme.surface,
      );

  /// Custom Color 1
  static const customColor1 = ExtendedColor(
    seed: Color(4278370714),
    value: Color(4278370714),
    light: ColorFamily(
      color: Color(4278217557),
      onColor: Color(4294967295),
      colorContainer: Color(4280798629),
      onColorContainer: Color(4278202405),
    ),
    lightMediumContrast: ColorFamily(
      color: Color(4278217557),
      onColor: Color(4294967295),
      colorContainer: Color(4280798629),
      onColorContainer: Color(4278202405),
    ),
    lightHighContrast: ColorFamily(
      color: Color(4278217557),
      onColor: Color(4294967295),
      colorContainer: Color(4280798629),
      onColorContainer: Color(4278202405),
    ),
    dark: ColorFamily(
      color: Color(4283098298),
      onColor: Color(4278204459),
      colorContainer: Color(4278237587),
      onColorContainer: Color(4278197268),
    ),
    darkMediumContrast: ColorFamily(
      color: Color(4283098298),
      onColor: Color(4278204459),
      colorContainer: Color(4278237587),
      onColorContainer: Color(4278197268),
    ),
    darkHighContrast: ColorFamily(
      color: Color(4283098298),
      onColor: Color(4278204459),
      colorContainer: Color(4278237587),
      onColorContainer: Color(4278197268),
    ),
  );

  List<ExtendedColor> get extendedColors => [
        customColor1,
      ];
}

class MaterialScheme {
  const MaterialScheme({
    required this.brightness,
    required this.primary,
    required this.surfaceTint,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.tertiary,
    required this.onTertiary,
    required this.tertiaryContainer,
    required this.onTertiaryContainer,
    required this.error,
    required this.onError,
    required this.errorContainer,
    required this.onErrorContainer,
    required this.background,
    required this.onBackground,
    required this.surface,
    required this.onSurface,
    required this.surfaceVariant,
    required this.onSurfaceVariant,
    required this.outline,
    required this.outlineVariant,
    required this.shadow,
    required this.scrim,
    required this.inverseSurface,
    required this.inverseOnSurface,
    required this.inversePrimary,
    required this.primaryFixed,
    required this.onPrimaryFixed,
    required this.primaryFixedDim,
    required this.onPrimaryFixedVariant,
    required this.secondaryFixed,
    required this.onSecondaryFixed,
    required this.secondaryFixedDim,
    required this.onSecondaryFixedVariant,
    required this.tertiaryFixed,
    required this.onTertiaryFixed,
    required this.tertiaryFixedDim,
    required this.onTertiaryFixedVariant,
    required this.surfaceDim,
    required this.surfaceBright,
    required this.surfaceContainerLowest,
    required this.surfaceContainerLow,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.surfaceContainerHighest,
  });

  final Brightness brightness;
  final Color primary;
  final Color surfaceTint;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color secondary;
  final Color onSecondary;
  final Color secondaryContainer;
  final Color onSecondaryContainer;
  final Color tertiary;
  final Color onTertiary;
  final Color tertiaryContainer;
  final Color onTertiaryContainer;
  final Color error;
  final Color onError;
  final Color errorContainer;
  final Color onErrorContainer;
  final Color background;
  final Color onBackground;
  final Color surface;
  final Color onSurface;
  final Color surfaceVariant;
  final Color onSurfaceVariant;
  final Color outline;
  final Color outlineVariant;
  final Color shadow;
  final Color scrim;
  final Color inverseSurface;
  final Color inverseOnSurface;
  final Color inversePrimary;
  final Color primaryFixed;
  final Color onPrimaryFixed;
  final Color primaryFixedDim;
  final Color onPrimaryFixedVariant;
  final Color secondaryFixed;
  final Color onSecondaryFixed;
  final Color secondaryFixedDim;
  final Color onSecondaryFixedVariant;
  final Color tertiaryFixed;
  final Color onTertiaryFixed;
  final Color tertiaryFixedDim;
  final Color onTertiaryFixedVariant;
  final Color surfaceDim;
  final Color surfaceBright;
  final Color surfaceContainerLowest;
  final Color surfaceContainerLow;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color surfaceContainerHighest;
}

extension MaterialSchemeUtils on MaterialScheme {
  ColorScheme toColorScheme() {
    return ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      secondary: secondary,
      onSecondary: onSecondary,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: onSecondaryContainer,
      tertiary: tertiary,
      onTertiary: onTertiary,
      tertiaryContainer: tertiaryContainer,
      onTertiaryContainer: onTertiaryContainer,
      error: error,
      onError: onError,
      errorContainer: errorContainer,
      onErrorContainer: onErrorContainer,
      background: background,
      onBackground: onBackground,
      surface: surface,
      onSurface: onSurface,
      surfaceVariant: surfaceVariant,
      onSurfaceVariant: onSurfaceVariant,
      outline: outline,
      outlineVariant: outlineVariant,
      shadow: shadow,
      scrim: scrim,
      inverseSurface: inverseSurface,
      onInverseSurface: inverseOnSurface,
      inversePrimary: inversePrimary,
    );
  }
}

class ExtendedColor {
  final Color seed, value;
  final ColorFamily light;
  final ColorFamily lightHighContrast;
  final ColorFamily lightMediumContrast;
  final ColorFamily dark;
  final ColorFamily darkHighContrast;
  final ColorFamily darkMediumContrast;

  const ExtendedColor({
    required this.seed,
    required this.value,
    required this.light,
    required this.lightHighContrast,
    required this.lightMediumContrast,
    required this.dark,
    required this.darkHighContrast,
    required this.darkMediumContrast,
  });
}

class ColorFamily {
  const ColorFamily({
    required this.color,
    required this.onColor,
    required this.colorContainer,
    required this.onColorContainer,
  });

  final Color color;
  final Color onColor;
  final Color colorContainer;
  final Color onColorContainer;
}
