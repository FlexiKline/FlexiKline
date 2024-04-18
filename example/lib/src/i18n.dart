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
import 'package:example/src/utils/cache_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';

const String cacheKeyLocale = 'cache_key_locale';

final localProvider = StateProvider<Locale>((ref) {
  throw UnimplementedError();
});

class I18nManager {
  I18nManager._internal();
  factory I18nManager() => _instance;
  static final I18nManager _instance = I18nManager._internal();
  static I18nManager get instance => _instance;

  final List<ValueChanged<Locale>> _localeListeners = [];

  Iterable<LocalizationsDelegate<dynamic>> get localizationsDelegates => const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate
      ];

  List<Locale> get supportedLocales => S.delegate.supportedLocales;

  Locale init() {
    final String? cache = CacheUtil().get(cacheKeyLocale);
    if (cache != null) {
      final list = cache.split('-');
      if (list.length == 1) {
        return Locale(list[0]);
      } else if (list.length == 2) {
        return Locale(list[0], list[1]);
      } else if (list.length > 2) {
        return Locale.fromSubtags(
          languageCode: list[0],
          scriptCode: list[1],
          countryCode: list[2],
        );
      }
    }
    return supportedLocales.first;
  }

  void switchLocale(Locale locale) {
    final curr = globalNavigatorKey.ref.read(localProvider);
    if (curr != locale) {
      globalNavigatorKey.ref.read(localProvider.notifier).state = locale;
      CacheUtil().setString(cacheKeyLocale, locale.toLanguageTag());
      for (var cb in _localeListeners) {
        cb(locale);
      }
    }
  }

  void registerListener(ValueChanged listener) {
    _localeListeners.add(listener);
  }

  void removeListener(ValueChanged listener) {
    _localeListeners.remove(listener);
  }

  String convert(Locale locale) {
    if (locale.languageCode == 'en') {
      return "English";
    } else if (locale.languageCode == 'zh') {
      return "中文";
    } else {
      return "";
    }
  }
}
