// Copyright 2024 Andy.Zhao
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:example/generated/l10n.dart';
import 'package:example/src/router.dart';
import 'package:example/src/utils/cache_util.dart';
import 'package:flex_seed_scheme/flex_seed_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const cacheKeyTheme = 'key_theme';

// but with always black and white contrasting onColors.
final ColorScheme schemeLightOnBW = SeedColorScheme.fromSeeds(
  brightness: Brightness.light,
  primaryKey: const Color(0xFF1F2860),
  secondaryKey: const Color(0xFF21518F),
  tertiaryKey: const Color(0xFF327BD2),
  errorKey: const Color(0xFFDD5858),
  tones: FlexTones.material(Brightness.light)
    ..onMainsUseBW().onSurfacesUseBW().surfacesUseBW(),
);

// Make a Vivid dark ColorScheme,
// but with always black and white contrasting onColors.
final ColorScheme schemeDarkOnBW = SeedColorScheme.fromSeeds(
  brightness: Brightness.dark,
  primaryKey: const Color(0xFF1F2860),
  secondaryKey: const Color(0xFF21518F),
  tertiaryKey: const Color(0xFF327BD2),
  errorKey: const Color(0xFFDD5858),
  tones: FlexTones.vivid(Brightness.dark)
    ..onMainsUseBW().onSurfacesUseBW().surfacesUseBW(),
);

final lightTheme = ThemeData(
  colorScheme: schemeLightOnBW,
  useMaterial3: true,
  scaffoldBackgroundColor: const Color(0xffF8F9FB),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: const Color(0xffFEFEFF),
  ),
);

final darkTheme = ThemeData(
  colorScheme: schemeDarkOnBW,
  useMaterial3: true,
  scaffoldBackgroundColor: const Color(0xFF121212),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: const Color(0xFF1A1A1A),
  ),
);

final themeModeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.system;
});

class ThemeManager {
  ThemeManager._internal();
  factory ThemeManager() => _instance;
  static final ThemeManager _instance = ThemeManager._internal();
  static ThemeManager get instance => _instance;

  final List<ValueChanged<ThemeMode>> _themeModeListeners = [];

  ThemeMode init() {
    final String? theme = CacheUtil().get(cacheKeyTheme);
    if (theme != null) {
      return ThemeMode.values.firstWhere(
        (e) => e.name == theme,
        orElse: () => ThemeMode.system,
      );
    }
    return ThemeMode.system;
  }

  void swithThemeMode(ThemeMode mode) {
    final curr = globalNavigatorKey.ref.read(themeModeProvider);
    if (curr != mode) {
      globalNavigatorKey.ref.read(themeModeProvider.notifier).state = mode;
      CacheUtil().setString(cacheKeyTheme, mode.name);
      for (var cb in _themeModeListeners) {
        cb(mode);
      }
    }
  }

  void registerListener(ValueChanged listener) {
    _themeModeListeners.add(listener);
  }

  void removeListener(ValueChanged listener) {
    _themeModeListeners.remove(listener);
  }

  String convert(ThemeMode mode, {S? s}) {
    s ??= S.current;
    switch (mode) {
      case ThemeMode.system:
        return s.themeModeSystem;
      case ThemeMode.light:
        return s.themeModeLight;
      case ThemeMode.dark:
        return s.themeModeDark;
    }
  }
}
