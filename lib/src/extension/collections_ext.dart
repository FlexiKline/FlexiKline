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

import 'dart:collection';

extension ListExt<T> on List<T> {
  bool checkIndex(int index) {
    return index >= 0 && index < length;
  }

  T? getItem(int index) {
    if (checkIndex(index)) return this[index];
    return null;
  }

  T? get secondOrNull {
    var iterator = this.iterator;
    iterator.moveNext();
    if (iterator.moveNext()) return iterator.current;
    return null;
  }

  bool get hasValidData {
    if (isEmpty) return false;
    for (T t in this) {
      if (t != null) return true;
    }
    return false;
  }
}

extension MapExt<K, V> on Map<K, V> {
  V? getItem(K? key) {
    if (key != null) return this[key];
    return null;
  }

  void setItem(K? key, V val) {
    if (key == null) return;
    this[key] = val;
  }

  @Deprecated('废弃, 不安全')
  T? obtainItem<T>(K? key) {
    if (key == null) return null;
    V? val = this[key];
    if (val == null) return null;
    if (val is Map && T == Map<String, dynamic>) {
      return Map<String, dynamic>.from(val) as T;
    } else if (val is List && T == List<String>) {
      return List<String>.from(val) as T;
    } else if (val is T) {
      return val as T;
    }
    return null;
  }
}

extension SetExt<T> on Set<T> {}

extension QueueExt<T> on Queue<T> {}
