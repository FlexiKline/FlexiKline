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

/// [GestureConfig.scalePosition] 的序列化: 写出 `.name`, 读回时未知值回退为构造默认值 auto。
library;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GestureConfig.scalePosition 序列化', () {
    test('各取值往返, 写出的 key 为枚举名', () {
      for (final position in ScalePosition.values) {
        final json = GestureConfig(scalePosition: position).toJson();
        expect(json['scalePosition'], position.name);
        expect(GestureConfig.fromJson(json).scalePosition, position);
      }
    });

    test('未知值回退为 auto', () {
      expect(GestureConfig.fromJson({'scalePosition': 'zzz'}).scalePosition, ScalePosition.auto);
    });

    test('键缺失或为 null 时回退为构造默认值 auto', () {
      expect(GestureConfig.fromJson({}).scalePosition, ScalePosition.auto);
      expect(GestureConfig.fromJson({'scalePosition': null}).scalePosition, ScalePosition.auto);
    });
  });
}
