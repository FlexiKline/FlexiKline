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

extension FlexiKlineNumExt on num {
  int get alpha {
    return (0xFF * this).round();
  }
}

extension FlexiKlineString on String {
  /// 首字母大写
  String capitalize() {
    if (isEmpty) return '';
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }

  /// Case-insensitive equals check
  bool equalsIgnoreCase(String? other) {
    return other != null && toLowerCase() == other.toLowerCase();
  }

  /// Case-insensitive contains check
  bool containsIgnoreCase(String? value) {
    return value != null && toLowerCase().contains(value.toLowerCase());
  }

  /// Convert to camelCase
  String toCamelCase() {
    // Handle empty or null string
    if (isEmpty) return '';

    // Split the string by underscores or hyphens
    List<String> words = split(RegExp(r'[_\-\s]'));

    // Capitalize each word except the first
    return words.asMap().entries.map((entry) {
      int index = entry.key;
      String word = entry.value;

      // First word stays lowercase, others get capitalized
      return index == 0 ? word.toLowerCase() : word.capitalize();
    }).join();
  }

  /// Convert to snake_case
  String toSnakeCase() {
    return replaceAllMapped(RegExp(r'([A-Z])'), (Match match) {
      return '_${match.group(0)!.toLowerCase()}';
    }).toLowerCase();
  }

  /// Remove all whitespace
  String get removeWhitespace => replaceAll(RegExp(r'\s+'), '');

  /// Remove special characters
  String trimSpecialCharacters() {
    return replaceAll(RegExp(r'[^a-zA-Z0-9 ]'), '');
  }
}
