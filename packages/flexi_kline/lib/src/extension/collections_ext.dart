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

extension FlexiKlineListExt<T> on List<T> {
  bool checkIndex(int index) {
    return index >= 0 && index < length;
  }

  T? getItem(int index) {
    if (checkIndex(index)) return this[index];
    return null;
  }

  int binarySearch(int Function(T item) compare) {
    int min = 0;
    int max = length;
    while (min < max) {
      final int mid = min + ((max - min) >> 1);
      final T element = this[mid];
      final int comp = compare(element);
      if (comp == 0) {
        return mid;
      }
      if (comp < 0) {
        min = mid + 1;
      } else {
        max = mid;
      }
    }
    return -1;
  }
}

extension FlexiIterableExt<T> on Iterable<T> {
  bool get hasValidData {
    if (isEmpty) return false;
    for (final t in this) {
      if (t != null) return true;
    }
    return false;
  }

  T? get secondOrNull {
    final iterator = this.iterator;
    iterator.moveNext();
    if (iterator.moveNext()) return iterator.current;
    return null;
  }

  T? get thirdOrNull {
    final iterator = this.iterator;
    iterator
      ..moveNext()
      ..moveNext();
    if (iterator.moveNext()) return iterator.current;
    return null;
  }

  /// Returns a new lazy [Iterable] with all `non-null` elements, or an empty iterable if the receiver is `null`.
  ///
  /// See [Iterable.where]
  Iterable<T> get nonNull => where((e) => e != null);

  /// Creates a fixed-length [List] containing the elements of this [Iterable],
  /// equivalent to `toList(growable: false)`.
  ///
  /// Returns an empty list if the receiver is `null`.
  ///
  /// See [Iterable.toList]
  List<T> asList() => toList(growable: false);

  /// Takes an action for each element.
  ///
  /// Calls [action] for each element along with the index in the
  /// iteration order.
  void forEachIndexed(void Function(int index, T element) action) {
    var index = 0;
    for (final element in this) {
      action(index++, element);
    }
  }

  /// Map each element and filter out the non-empty ones.
  Iterable<R> mapNonNullList<R>(R? Function(T element) convert) sync* {
    for (final element in this) {
      final item = convert(element);
      if (item != null) yield item;
    }
  }

  /// Maps each element and its index to a new value.
  Iterable<R> mapIndexed<R>(R Function(int index, T element) convert) sync* {
    var index = 0;
    for (final element in this) {
      yield convert(index++, element);
    }
  }

  /// The elements whose value and index satisfies [test].
  Iterable<T> whereIndexed(bool Function(int index, T element) test) sync* {
    var index = 0;
    for (final element in this) {
      if (test(index++, element)) yield element;
    }
  }

  /// obtain the elements in the range [start, end).
  Iterable<T> range(int start, [int? end]) sync* {
    if (start < 0) throw ArgumentError('start:$start must be non-negative');
    if (end != null && end <= start) {
      throw ArgumentError('end:$end must be greater than start:$start');
    }
    // assert(start >= 0, 'start:$start must be non-negative');
    // assert(end == null || end >= start, 'end:$end must be greater than start:$start');
    var index = 0;
    for (final element in this) {
      if (index >= start && (end == null || index < end)) {
        yield element;
      }
      index++;
    }
  }

  /// Combine the elements with each other and the current index.
  ///
  /// Calls [combine] for each element except the first.
  /// The call passes the index of the current element, the result of the
  /// previous call, or the first element for the first call, and
  /// the current element.
  ///
  /// Returns the result of the last call, or the first element if
  /// there is only one element.
  /// There must be at least one element.
  T reduceIndexed(T Function(int index, T previous, T element) combine) {
    final iterator = this.iterator;
    if (!iterator.moveNext()) {
      throw StateError('no elements');
    }
    var index = 1;
    var result = iterator.current;
    while (iterator.moveNext()) {
      result = combine(index++, result, iterator.current);
    }
    return result;
  }

  /// Combine the elements with a value and the current index.
  ///
  /// Calls [combine] for each element with the current index,
  /// the result of the previous call, or [initialValue] for the first element,
  /// and the current element.
  ///
  /// Returns the result of the last call to [combine],
  /// or [initialValue] if there are no elements.
  R foldIndexed<R>(R initialValue, R Function(int index, R previous, T element) combine) {
    var result = initialValue;
    var index = 0;
    for (final element in this) {
      result = combine(index++, result, element);
    }
    return result;
  }

  /// The second element that continuously satisfying [test], or `null` element if there are none.
  T? secondWhereOrNull(bool Function(T element) test) {
    final iterator = this.iterator;
    while (iterator.moveNext()) {
      if (test(iterator.current)) {
        if (iterator.moveNext() && test(iterator.current)) {
          return iterator.current;
        }
      }
    }
    return null;
  }

  /// The first element satisfying [test], or `null` if there are none.
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }

  /// The first element whose value and index satisfies [test].
  ///
  /// Returns `null` if there are no element and index satisfying [test].
  T? firstWhereIndexedOrNull(bool Function(int index, T element) test) {
    var index = 0;
    for (final element in this) {
      if (test(index++, element)) return element;
    }
    return null;
  }

  /// Groups elements by a key generated from each element.
  ///
  /// final users = [
  ///   {'name': 'John', 'age': 25},
  ///   {'name': 'Jane', 'age': 25}
  /// ];
  /// final byAge = users.groupBy((user) => user['age']);
  /// Result: {25: [{'name': 'John', 'age': 25}, {'name': 'Jane', 'age': 25}]}
  Map<K, List<T>> groupBy<K>(K Function(T) keyFunction) {
    return fold<Map<K, List<T>>>({}, (map, element) {
      final key = keyFunction(element);
      (map[key] ??= []).add(element);
      return map;
    });
  }

  /// Returns distinct elements based on a key function.
  ///
  /// final users = [
  ///   {'id': 1, 'name': 'John'},
  ///   {'id': 1, 'name': 'John Updated'}
  /// ];
  /// final unique = users.distinctBy((user) => user['id']);
  /// Result: [{'id': 1, 'name': 'John'}]
  Iterable<T> distinctBy<K>(K Function(T) keyFunction) {
    final seen = <K>{};
    return where((element) => seen.add(keyFunction(element)));
  }

  /// Splits iterable into chunks of specified size.
  ///
  /// [1, 2, 3, 4, 5].chunk(2)
  /// Result: [[1, 2], [3, 4], [5]]
  Iterable<List<T>> chunk(int size) sync* {
    if (size <= 0) throw ArgumentError('Size must be positive');
    final iterator = this.iterator;
    while (iterator.moveNext()) {
      final chunk = [iterator.current];
      for (var i = 1; i < size && iterator.moveNext(); i++) {
        chunk.add(iterator.current);
      }
      yield chunk;
    }
  }

  /// Returns element at index or null if out of bounds.
  ///
  /// [1, 2, 3].elementAtOrNull(5) // null
  /// [1, 2, 3].elementAtOrNull(1) // 2
  T? elementAtOrNull(int index) {
    if (index < 0) return null;
    var i = 0;
    for (final element in this) {
      if (i == index) return element;
      i++;
    }
    return null;
  }

  /// Shuffle list and return a new list
  ///
  /// [Returns] New shuffled list
  List<T> shuffled() {
    return List.of(this)..shuffle();
  }

  /// Converts iterable to a map with index as key.
  ///
  /// ['a', 'b', 'c'].toIndexMap()
  /// Result: {0: 'a', 1: 'b', 2: 'c'}
  Map<int, T> toIndexMap() {
    return Map.fromEntries(
      enumerate().map((entry) => MapEntry(entry.$1, entry.$2)),
    );
  }

  /// Returns iterable of (index, value) pairs.
  ///
  /// ['a', 'b'].enumerate()
  /// Result: [(0, 'a'), (1, 'b')]
  Iterable<(int, T)> enumerate() sync* {
    var index = 0;
    for (final element in this) {
      yield (index++, element);
    }
  }

  /// Returns sum of numeric elements or transformation.
  ///
  /// [1, 2, 3].sum() // 6
  /// ['a', 'bb', 'ccc'].sum((e) => e.length) // 6
  num sum([num Function(T)? selector]) {
    num result = 0;
    for (final element in this) {
      result += selector?.call(element) ?? (element as num);
    }
    return result;
  }

  /// Returns average of numeric elements or transformation.
  ///
  /// [1, 2, 3].average() // 2.0
  /// ['a', 'bb', 'ccc'].average((e) => e.length) // 2.0
  double average([num Function(T)? selector]) {
    if (isEmpty) return 0;
    return sum(selector) / length;
  }

  /// Partitions elements into two lists based on predicate.
  ///
  /// final numbers = [1, 2, 3, 4, 5];
  /// final (evens, odds) = numbers.partition((n) => n.isEven);
  /// evens: [2, 4], odds: [1, 3, 5]
  (List<T>, List<T>) partition(bool Function(T) predicate) {
    final matched = <T>[];
    final unmatched = <T>[];
    for (final element in this) {
      predicate(element) ? matched.add(element) : unmatched.add(element);
    }
    return (matched, unmatched);
  }

  /// Returns max element based on selector function.
  ///
  /// ['cat', 'elephant', 'dog'].maxBy((s) => s.length) // 'elephant'
  T? maxBy<R extends Comparable>(R Function(T) selector) {
    if (isEmpty) return null;
    return reduce((a, b) => selector(a).compareTo(selector(b)) > 0 ? a : b);
  }

  /// Returns min element based on selector function.
  ///
  /// ['cat', 'elephant', 'dog'].minBy((s) => s.length) // 'cat'
  T? minBy<R extends Comparable>(R Function(T) selector) {
    if (isEmpty) return null;
    return reduce((a, b) => selector(a).compareTo(selector(b)) <= 0 ? a : b);
  }

  /// Returns true if all elements are equal.
  ///
  /// [1, 1, 1].allEqual() // true
  /// [1, 2, 1].allEqual() // false
  bool allEqual() {
    if (isEmpty) return true;
    final first = elementAt(0);
    return every((element) => element == first);
  }

  /// Convert an Iterable to a map through [test].
  /// If [test] returns null, the element will be ignored.
  Map<K, T> toMap<K>(MapEntry<K, T>? Function(T item) test) {
    if (isEmpty) return const {};
    final entries = <MapEntry<K, T>>[];
    for (final element in this) {
      final entry = test(element);
      if (entry != null) entries.add(entry);
    }
    return Map.fromEntries(entries);
  }
}

extension FlexiMapExt<K, V> on Map<K, V> {
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
    final val = this[key];
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
