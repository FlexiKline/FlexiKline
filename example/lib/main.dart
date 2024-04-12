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

import 'package:example/src/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app.dart';
import 'src/config.dart';
import 'src/i18n.dart';
import 'src/repo/http_client.dart';
import 'src/utils/cache_util.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await CacheUtil().init();

  final locale = I18nManager().init();
  final themeMode = ThemeManager().init();

  initHttpClient();

  runApp(ProviderScope(
    overrides: [
      localProvider.overrideWith((ref) => locale),
      themeModeProvider.overrideWith((ref) => themeMode),
    ],
    observers: [AppProviderObserver()],
    child: const MyApp(
      extraNavObservers: [],
    ),
  ));
}
