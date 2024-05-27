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
import 'package:example/src/i18n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/theme_manager.dart';

class SettingDrawer extends StatelessWidget {
  const SettingDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      key: key,
      width: ScreenUtil().screenWidth * 0.75,
      child: const SettingPage(
        key: ValueKey('setting'),
      ),
    );
  }
}

class SettingPage extends ConsumerStatefulWidget {
  const SettingPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SettingPageState();
}

class _SettingPageState extends ConsumerState<SettingPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final currLocale = ref.watch(localProvider);
    final currThemeMode = ref.watch(themeModeProvider);
    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.settings_rounded),
        title: Text(
          s.setting,
          style: theme.textTheme.titleLarge,
        ),
      ),
      body: Container(
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: 16.r,
          vertical: 10.r,
        ),
        child: SingleChildScrollView(
          child: Theme(
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: Column(
              children: [
                ExpansionTile(
                  title: Text(
                    s.settingLanguage,
                    style: theme.textTheme.titleMedium,
                  ),
                  leading: const Icon(Icons.language_rounded),
                  initiallyExpanded: true,
                  children: I18nManager().supportedLocales.map((locale) {
                    return ListTile(
                      key: ValueKey(locale),
                      title: Text(
                        I18nManager().convert(locale),
                        style: theme.textTheme.bodyMedium,
                      ),
                      trailing: currLocale == locale
                          ? const Icon(Icons.check_rounded)
                          : null,
                      onTap: () {
                        I18nManager().switchLocale(locale);
                      },
                    );
                  }).toList(),
                ),
                SizedBox(height: 8.r),
                ExpansionTile(
                  title: Text(
                    s.settingThemeMode,
                    style: theme.textTheme.titleMedium,
                  ),
                  leading: const Icon(Icons.palette_rounded),
                  initiallyExpanded: true,
                  children: ThemeMode.values.map((mode) {
                    return ListTile(
                      key: ValueKey(mode),
                      title: Text(
                        ThemeManager().convert(mode, s: s),
                        style: theme.textTheme.bodyMedium,
                      ),
                      trailing: currThemeMode == mode
                          ? const Icon(Icons.check_rounded)
                          : null,
                      onTap: () {
                        ThemeManager().swithThemeMode(mode);
                      },
                    );
                  }).toList(),
                ),
                SizedBox(height: 8.r),
                ExpansionTile(
                  title: Text(
                    s.about,
                    style: theme.textTheme.titleMedium,
                  ),
                  leading: const Icon(Icons.error_outline_rounded),
                  children: [
                    ListTile(
                      title: Text(
                        'v0.1.0',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
