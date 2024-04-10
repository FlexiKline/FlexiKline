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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final localProvider = StateProvider<Locale>((ref) {
  throw UnimplementedError();
});

class AppProviderObserver extends ProviderObserver {
  AppProviderObserver();

  @override
  Future<void> didUpdateProvider(
    ProviderBase<dynamic> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) async {
    if (kDebugMode) {
      debugPrint('PROVIDER    : ${provider.name ?? '<NO NAME>'}\n'
          '  Type      : ${provider.runtimeType}\n'
          '  Old value : $previousValue\n'
          '  New value : $newValue');
    }
  }
}
