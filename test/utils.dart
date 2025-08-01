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

import 'package:flutter/material.dart';

void printIterable<T>(Iterable<T> list, {String? tag}) {
  for (var val in list) {
    debugPrint('${tag ?? ''}>${val.toString()}');
  }
}

void printMap<K, V>(Map<K, V> map, {String? tag}) {
  map.forEach((key, val) {
    debugPrint('${tag ?? ''}> key:$key \t val:${val.toString()}');
  });
}

void logMsg(dynamic msg) {
  debugPrint(msg.toString());
}
