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

import 'dart:convert';

import 'package:flutter/material.dart';

import 'common.dart';
import 'indicator.dart';
import 'logger.dart';

typedef IndicatorFromJson<T extends Indicator> = T Function(
  Map<String, dynamic>,
);

abstract interface class IStore {
  T? get<T>(
    String key, {
    T? def,
  });

  Future<bool> set<T>(
    String key,
    T value,
  );

  Future<bool> remove(String key);

  bool contains(String key);
}

mixin KlineStorage implements IStore, ILogger {
  IStore? storeDelegate;

  @override
  T? get<T>(
    String key, {
    T? def,
  }) {
    return storeDelegate?.get(key, def: def);
  }

  @override
  Future<bool> set<T>(String key, T value) async {
    return await storeDelegate?.set(key, value) ?? false;
  }

  @override
  Future<bool> remove(String key) async {
    return await storeDelegate?.remove(key) ?? false;
  }

  @override
  bool contains(String key) {
    return storeDelegate?.contains(key) ?? false;
  }

  String _valueKeyToString(ValueKey key) {
    if (key.value is IndicatorType) {
      return key.value.toString();
    }
    return key.value.toString();
  }

  T? restoreIndicator<T extends Indicator>(
    ValueKey key,
    IndicatorFromJson<T> fromJson,
  ) {
    if (storeDelegate == null) return null;
    try {
      final String? jsonStr = storeDelegate!.get(_valueKeyToString(key));
      if (jsonStr != null && jsonStr.trim().isNotEmpty) {
        final json = jsonDecode(jsonStr);
        return fromJson(json);
      }
    } catch (err, stack) {
      loge(
        'restoreIndicator error',
        error: err,
        stackTrace: stack,
      );
    }
    return null;
  }

  Future<bool> saveIndicator(ValueKey key, Map<String, dynamic> json) async {
    if (storeDelegate == null) return false;
    return storeDelegate!.set(_valueKeyToString(key), jsonEncode(json));
  }
}
