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

/// FIFOHashMap
/// 先进先出的HashMap
/// 主要特性:
/// 1. 可设置固定容量.
/// 2. 按加入顺序迭代
/// 3. 添加元素时,
/// 3.1 当超出容量, 先删除最先添加的元素, 并返回删除的旧元素.
/// 3.2 如果key已经存在, 则先删除key指代元素, 再添加key/value对, 始终保证Key和value均为最新的.
class FIFOHashMap<K, V> with MapBase<K, V> {
  FIFOHashMap({
    int? capacity,
  }) : _capacity = capacity != null && capacity > 0 ? capacity : null;
  final int? _capacity;
  final LinkedHashMap<K, V> _map = LinkedHashMap<K, V>();

  @override
  V? operator [](Object? key) => _map[key];

  V? get(Object? key) => this[key];

  V? append(K key, V value) {
    V? old;
    if (_capacity != null && length >= _capacity && !_map.containsKey(key)) {
      old = remove(_map.keys.firstOrNull);
    }
    if (_map.containsKey(key)) remove(key);
    _map[key] = value;
    return old;
  }

  @override
  void operator []=(K key, V value) {
    append(key, value);
  }

  @override
  void clear() {
    _map.clear();
  }

  @override
  Iterable<K> get keys => _map.keys;

  @override
  V? remove(Object? key) => _map.remove(key);
}
