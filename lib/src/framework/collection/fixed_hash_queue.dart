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

/// 固定大小的Hash队列
/// 
/// [fixedCapacity] 固定容量, 必须大于0
/// 主要特性.
/// 1. 固定容量.
/// 2. 元素无重复.
/// 3. 添加元素时, 如果队列已经存在此元素(即equals和hashcode 相等), 则执行更新操作, 并保留元素在队列中的位置.
/// 4. [addLast]|[add] : 向队尾追加元素时, 如果队列已满: 则删除队列最前面的元素.
/// 5. [addFirst] : 向队前追加元素时, 如果队列已满: 则删除队列最尾的元素.
/// 实现在[append]中.
class FixedHashQueue<E> implements Queue<E> {
  FixedHashQueue(this.fixedCapacity)
      : assert(fixedCapacity > 0, 'fixedCapacity must be greater than 0'),
        _queue = ListQueue<E>(fixedCapacity);

  final int fixedCapacity;
  ListQueue<E> _queue;

  /// 向队列中追加元素. 并返回旧的元素(如果存在)
  /// 1. 如果已经存在元素[value], 则替换之, 并返回旧的元素.
  /// 2. 如果不存在此元素[value], 则在队尾/队前追加, 并返回null.
  E? append(E value, {bool atFirst = false}) {
    if (fixedCapacity <= 0) return null;

    if (_queue.contains(value)) {
      E? oldElement;
      final newQueue = ListQueue<E>(fixedCapacity);
      for (E e in _queue) {
        if (e == value) {
          oldElement = e;
          newQueue.add(value);
        } else {
          newQueue.add(e);
        }
      }
      _queue = newQueue;
      return oldElement;
    } else {
      if (atFirst) {
        if (length >= fixedCapacity) _queue.removeLast();
        _queue.addFirst(value);
      } else {
        if (length >= fixedCapacity) _queue.removeFirst();
        _queue.addLast(value);
      }
      return null;
    }
  }

  /// 添加[iterable]集合到队列中.
  /// [disposeElement] 如果不为空, 则在添加过程中, 发生替换操作时, 会回调原队列旧元素, 方便dispose.
  void appendAll(
    Iterable<E> iterable, {
    void Function(E value)? disposeElement,
  }) {
    iterable.toSet().forEach((element) {
      final old = append(element);
      if (disposeElement != null && old != null) disposeElement(old);
    });
  }

  @override
  void addFirst(E value) => append(value, atFirst: true);

  @override
  void add(E value) => append(value);

  @override
  void addLast(E value) => append(value);

  @override
  void addAll(Iterable<E> iterable, {void Function(E value)? disposeElement}) {
    appendAll(iterable, disposeElement: disposeElement);
  }

  @override
  void clear() {
    _queue.clear();
  }

  @override
  bool remove(Object? value) {
    return _queue.remove(value);
  }

  @override
  E removeFirst() {
    return _queue.removeFirst();
  }

  @override
  E removeLast() {
    return _queue.removeLast();
  }

  @override
  void removeWhere(bool Function(E element) test) {
    _queue.removeWhere(test);
  }

  @override
  void retainWhere(bool Function(E element) test) {
    _queue.retainWhere(test);
  }

  @override
  E get first => _queue.first;

  @override
  E get last => _queue.last;

  @override
  E get single => _queue.single;

  @override
  int get length => _queue.length;

  @override
  bool get isEmpty => _queue.isEmpty;

  @override
  bool get isNotEmpty => _queue.isNotEmpty;

  @override
  Iterator<E> get iterator => _queue.iterator;

  @override
  Queue<R> cast<R>() => _queue.cast();

  @override
  bool any(bool Function(E element) test) => _queue.any(test);

  @override
  bool contains(Object? element) => _queue.contains(element);

  @override
  E elementAt(int index) => _queue.elementAt(index);

  @override
  bool every(bool Function(E element) test) => _queue.every(test);

  @override
  E firstWhere(bool Function(E element) test, {E Function()? orElse}) {
    return _queue.firstWhere(test, orElse: orElse);
  }

  @override
  T fold<T>(T initialValue, T Function(T previousValue, E element) combine) {
    return _queue.fold(initialValue, combine);
  }

  @override
  void forEach(void Function(E element) action) => _queue.forEach(action);

  @override
  String join([String separator = ""]) => _queue.join(separator);

  @override
  E lastWhere(bool Function(E element) test, {E Function()? orElse}) {
    return _queue.lastWhere(test, orElse: orElse);
  }

  @override
  E reduce(E Function(E value, E element) combine) => _queue.reduce(combine);

  @override
  E singleWhere(bool Function(E element) test, {E Function()? orElse}) {
    return _queue.singleWhere(test, orElse: orElse);
  }

  @override
  Iterable<T> expand<T>(Iterable<T> Function(E element) toElements) {
    return _queue.expand(toElements);
  }

  @override
  Iterable<E> followedBy(Iterable<E> other) => _queue.followedBy(other);

  @override
  Iterable<T> map<T>(T Function(E e) toElement) => _queue.map(toElement);

  @override
  Iterable<E> skip(int count) => _queue.skip(count);

  @override
  Iterable<E> skipWhile(bool Function(E value) test) => _queue.skipWhile(test);

  @override
  Iterable<E> take(int count) => _queue.take(count);

  @override
  Iterable<E> takeWhile(bool Function(E value) test) => _queue.takeWhile(test);

  @override
  List<E> toList({bool growable = true}) => _queue.toList(growable: growable);

  @override
  Set<E> toSet() => _queue.toSet();

  @override
  Iterable<E> where(bool Function(E element) test) => _queue.where(test);

  @override
  Iterable<T> whereType<T>() => _queue.whereType();

  @override
  String toString() => IterableBase.iterableToFullString(_queue, '[', ']');
}
