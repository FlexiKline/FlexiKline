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

import 'src/app.dart';
import 'src/preset.dart';

/// 手动冒烟入口: `flutter run --profile --dart-define=PRESET=full`, 用手指操作并在 DevTools 里看帧。
///
/// 正式采集走 `integration_test/bench_test.dart`(见 `tool/benchmark/device.sh`)。
void main() {
  runApp(
    BenchApp(
      preset: BenchPreset.parse(const String.fromEnvironment('PRESET', defaultValue: 'full')),
    ),
  );
}
