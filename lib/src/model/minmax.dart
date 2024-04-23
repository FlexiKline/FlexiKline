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

import 'package:decimal/decimal.dart';

class MinMax {
  MinMax({required this.max, required this.min});
  Decimal max;
  Decimal min;

  static final MinMax zero = MinMax(max: Decimal.zero, min: Decimal.zero);

  MinMax clone() => MinMax(max: max, min: min);

  void updateMinMaxByVal(Decimal val) {
    max = val > max ? val : max;
    min = val < min ? val : min;
  }

  void updateMinMax(MinMax? newVal) {
    if (newVal == null) return;
    max = newVal.max > max ? newVal.max : max;
    min = newVal.min < min ? newVal.min : min;
  }

  Decimal get size => max - min;

  @override
  String toString() {
    return 'MinMax(max:${max.toStringAsFixed(4)}, min:${min.toStringAsFixed(4)})';
  }
}
