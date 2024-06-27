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

int _dynamicCompare(dynamic a, dynamic b) => Comparable.compare(a, b);

Comparator<K> _defaultCompare<K>() {
  // If K <: Comparable, then we can just use Comparable.compare
  // with no casts.
  Object compare = Comparable.compare;
  if (compare is Comparator<K>) {
    return compare;
  }
  // Otherwise wrap and cast the arguments on each call.
  return _dynamicCompare;
}

/// 可排序的HashSet
/// 
/// [compare] 排序比较器, 如果不指定, 请确保元素[E]实现Comparable<E>接口.
/// 主要特性:
/// 1. 添加元素[add]时, 如果存在, 则更新元素, 并返回true.
/// 2. 添加元素[append]时, 如果存在, 则更新元素, 并返回旧元素.
/// 3. 迭代元素时, 是已排序的列表.
final class SortableHashSet<E> with SetMixin<E> {
  SortableHashSet([
    Set<E>? set,
    Comparator? compare,
  ])  : _compare = compare ?? _defaultCompare<E>(),
        _set = set ?? <E>{};

  factory SortableHashSet.from(
    Iterable<dynamic> elements, [
    Comparator? compare,
  ]) {
    LinkedHashSet<E> result = LinkedHashSet<E>();
    for (final element in elements) {
      result.add(element as E);
    }
    return SortableHashSet(result, compare);
  }

  Comparator<E> _compare;
  final Set<E> _set;
  List<E>? __list;

  List<E> get _list {
    return __list ??= _set.toList(growable: false)..sort(_compare);
  }

  /// 追回[value]并返回旧元素(如果存在).
  E? append(E value) {
    final old = _set.lookup(value);
    if (add(value)) return old;
    return null;
  }

  /// 添加[elements]集合到队列中.
  /// [disposeElement] 如果不为空, 则在添加过程中, 发生替换操作时, 会回调原列表旧元素, 方便dispose.
  void appendAll(
    Iterable<E> elements, {
    void Function(E value)? disposeElement,
  }) {
    for (var element in elements) {
      final old = append(element);
      if (disposeElement != null && old != null) disposeElement(old);
    }
  }

  @override
  bool add(E value) {
    final result = _set.remove(value);
    _set.add(value);
    __list = null;
    return result;
  }

  @override
  void addAll(Iterable<E> elements, {void Function(E value)? disposeElement}) {
    appendAll(elements, disposeElement: disposeElement);
  }

  @override
  E? lookup(Object? element) {
    for (var e in _set) {
      if (e == element) return e;
    }
    return null;
  }

  @override
  bool remove(Object? value) {
    final result = _set.remove(value);
    if (result) __list = null;
    return result;
  }

  @override
  bool contains(Object? element) {
    return _set.contains(element);
  }

  @override
  Iterator<E> get iterator => _list.iterator;

  @override
  int get length => _list.length;

  @override
  Set<E> toSet() {
    Set<E> result = <E>{};
    for (int i = 0; i < length; i++) {
      result.add(_list[i]);
    }
    return result;
  }
}
