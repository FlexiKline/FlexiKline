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

library;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/lifecycle_spy.dart';

void main() {
  test('公开面可见：用户生命周期回调 + External 默认 keepAlive', () {
    final log = LifecycleLog();
    final obj = SpyExternalIndicator(key: const ExternalIndicatorKey('biz_a'), log: log).createPaintObject();
    // 本测试仅验证公开面可用；do* 的不外泄由 flexi_kline.dart 的 hide + 静态扫描保障。
    expect(obj, isA<ExternalPaintObject>());
    expect(obj.keepAlive, isTrue);
  });
}
