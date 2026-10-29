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

import 'package:flutter_test/flutter_test.dart';

import 'property.dart';

void main() {
  group('v2.2.0/support/forAll', () {
    test('运行 runs 次且确定性（同 description 同序列）', () {
      final a = <int>[];
      forAll('seq', generate: (rng) => rng.nextInt(1000), check: a.add, runs: 50);
      final b = <int>[];
      forAll('seq', generate: (rng) => rng.nextInt(1000), check: b.add, runs: 50);
      expect(a.length, 50);
      expect(a, equals(b));
    });

    test('check 失败时消息带上 seed、轮次与输入', () {
      expect(
        () =>
            forAll('fail', generate: (rng) => rng.nextInt(10), check: (v) => expect(v, lessThan(0)), runs: 3, seed: 7),
        throwsA(
          isA<TestFailure>().having((f) => f.message, 'message', allOf(contains('seed=7'), contains('run=0'))),
        ),
      );
    });

    test('自定义 seed 覆盖 description hash', () {
      final a = <int>[];
      forAll('x', generate: (rng) => rng.nextInt(100), check: a.add, runs: 10, seed: 999);
      final b = <int>[];
      forAll('y', generate: (rng) => rng.nextInt(100), check: b.add, runs: 10, seed: 999);
      expect(a, equals(b));
    });
  });
}
