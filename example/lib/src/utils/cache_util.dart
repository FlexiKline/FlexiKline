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

import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../repo/http_client.dart';

class CacheUtil {
  CacheUtil._internal();
  factory CacheUtil() => _instance;
  static final CacheUtil _instance = CacheUtil._internal();
  static CacheUtil get instance => _instance;

  late final SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<bool> remove(String key) {
    return _prefs.remove(key);
  }

  Future<bool> clear() {
    return _prefs.clear();
  }

  T? get<T>(String key, {T? def}) {
    return _prefs.get(key) as T? ?? def;
  }

  Future<bool> setString(String key, String value) {
    return _prefs.setString(key, value);
  }

  Future<bool> setDouble(String key, double value) {
    return _prefs.setDouble(key, value);
  }

  Future<bool> setInt(String key, int value) {
    return _prefs.setInt(key, value);
  }

  Future<bool> setBool(String key, bool value) {
    return _prefs.setBool(key, value);
  }

  Future<bool> setStringList(String key, List<String> value) {
    return _prefs.setStringList(key, value);
  }

  List<String> getStringList(
    String key, {
    List<String> def = const [],
  }) {
    return _prefs.getStringList(key) ?? def;
  }

  T? getModel<T>(String key, ModelMapper<T> modelMapper) {
    try {
      final String? jsonStr = get(key);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final json = jsonDecode(jsonStr);
        return modelMapper(json);
      }
    } catch (err, stack) {
      logger.e('getModel error:$err', stackTrace: stack);
    }
    return null;
  }

  void setModel<T>(String key, T data) {
    final jsonSrc = jsonEncode(data);
    setString(key, jsonSrc);
  }

  List<T>? getModelList<T>(String key, ModelMapper<T> modelMapper) {
    try {
      final String? jsonStr = get(key);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final json = jsonDecode(jsonStr);
        return (json as List<dynamic>?)?.map((e) => modelMapper(e)).toList() ??
            const [];
      }
    } catch (err, stack) {
      logger.e('getModelList error:$err', stackTrace: stack);
    }
    return null;
  }

  void setModelList<T>(String key, List<T> list) {
    final jsonSrc = jsonEncode(list);
    setString(key, jsonSrc);
  }
}
