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

/// [LineConfig.type] 的序列化: 写出 `.name`, 读回时缺失、null 与未知值都回退到构造默认值。
library;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LineConfig.type 序列化', () {
    test('三种线型各自往返, 写出的 key 为枚举名', () {
      for (final type in LineType.values) {
        final json = LineConfig(type: type).toJson();
        expect(json['type'], type.name);
        expect(LineConfig.fromJson(json).type, type);
      }
    });

    test('未知值回退为 solid, 与构造默认值一致', () {
      final json = {'type': 'zigzag'};
      expect(LineConfig.fromJson(json).type, LineType.solid);
    });

    test('键缺失或为 null 时回退为构造默认值 solid', () {
      expect(LineConfig.fromJson({}).type, LineType.solid);
      expect(LineConfig.fromJson({'type': null}).type, LineType.solid);
    });

    test('大小写不一致视为未知值, 回退为 solid', () {
      expect(LineConfig.fromJson({'type': 'DASHED'}).type, LineType.solid);
    });
  });
}
