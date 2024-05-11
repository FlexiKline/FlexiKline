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
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../router.dart';
import '../utils/cache_util.dart';

const cacheKeyTheme = 'cache_key_theme';

final themeModeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.system;
});

class ThemeManager {
  ThemeManager._internal();
  factory ThemeManager() => _instance;
  static final ThemeManager _instance = ThemeManager._internal();
  static ThemeManager get instance => _instance;

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
    }
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
