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

/// 属性测试入口：generate 生成输入，check 做断言。
library;

import 'dart:math';

/// seed 默认由 [description] 派生，免去手工 seed 簿记。
void forAll<T>(
  String description, {
  required T Function(Random rng) generate,
  required void Function(T value) check,
  int runs = 100,
  int? seed,
}) {
  final s = seed ?? description.hashCode;
  final rng = Random(s);
  for (int run = 0; run < runs; run++) {
    final value = generate(rng);
    check(value);
  }
}
