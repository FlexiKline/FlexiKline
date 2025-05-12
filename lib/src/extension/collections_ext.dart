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
    for (T t in this) {
      if (t != null) return true;
    }
    return false;
  }

  T? get secondOrNull {
    var iterator = this.iterator;
    iterator.moveNext();
    if (iterator.moveNext()) return iterator.current;
    return null;
  }

  T? get thirdOrNull {
    var iterator = this.iterator;
    iterator
      ..moveNext()
      ..moveNext();
    if (iterator.moveNext()) return iterator.current;
    return null;
  }

  /// Takes an action for each element.
  ///
  /// Calls [action] for each element along with the index in the
  /// iteration order.
  void forEachIndexed(void Function(int index, T element) action) {
    var index = 0;
    for (var element in this) {
      action(index++, element);
    }
  }

  /// Map each element and filter out the non-empty ones.
  Iterable<R> mapNonNullList<R>(R? Function(T element) convert) sync* {
    for (var element in this) {
      final item = convert(element);
      if (item != null) yield item;
    }
  }

  /// Maps each element and its index to a new value.
  Iterable<R> mapIndexed<R>(R Function(int index, T element) convert) sync* {
    var index = 0;
    for (var element in this) {
      yield convert(index++, element);
    }
  }

  /// The elements whose value and index satisfies [test].
  Iterable<T> whereIndexed(bool Function(int index, T element) test) sync* {
    var index = 0;
    for (var element in this) {
      if (test(index++, element)) yield element;
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
    var iterator = this.iterator;
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
    for (var element in this) {
      result = combine(index++, result, element);
    }
    return result;
  }

  /// The first element satisfying [test], or `null` if there are none.
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }

  /// The first element whose value and index satisfies [test].
  ///
  /// Returns `null` if there are no element and index satisfying [test].
  T? firstWhereIndexedOrNull(bool Function(int index, T element) test) {
    var index = 0;
    for (var element in this) {
      if (test(index++, element)) return element;
    }
    return null;
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
