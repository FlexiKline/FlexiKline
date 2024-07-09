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
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../i18n.dart';
import '../theme/theme_manager.dart';
import '../utils/device_util.dart';

class AppSettingDrawer extends StatelessWidget {
  const AppSettingDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      key: key,
      width: DeviceUtil.isMobile ? ScreenUtil().screenWidth * 0.75 : 300.r,
      child: const AppSettingPage(
        key: ValueKey('app_setting'),
      ),
    );
  }
}

class AppSettingPage extends ConsumerStatefulWidget {
  const AppSettingPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _AppSettingPageState();
}

class _AppSettingPageState extends ConsumerState<AppSettingPage> {
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
                  initiallyExpanded: false,
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
                  initiallyExpanded: false,
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
                    'Test Demo',
                    style: theme.textTheme.titleMedium,
                  ),
                  initiallyExpanded: true,
                  children: [
                    ListTile(
                      onTap: () {
                        context.pushNamed('accurateKline');
                      },
                      title: Text(
                        'Fast Vs Accurate Demo',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
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
                      title: FutureBuilder(
                        future: DeviceUtil.version(),
                        builder: (context, snapshot) => Text(
                          snapshot.data ?? '',
                          style: theme.textTheme.bodyMedium,
                        ),
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
