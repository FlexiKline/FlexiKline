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

import 'dart:math' as math;
import 'package:flutter/material.dart';

final class MaParam {
  final String label;
  final int count;
  final Color color;

  const MaParam({
    required this.label,
    required this.count,
    required this.color,
  });
}

final class EMAParam {
  final String label;
  final int count;
  final Color color;

  const EMAParam({
    required this.label,
    required this.count,
    required this.color,
  });
}

final class BOLLParam {
  final int n;
  final int std;

  const BOLLParam({required this.n, required this.std});

  bool get isValid => n > 0 && std > 0;

  @override
  int get hashCode => n.hashCode ^ std.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BOLLParam &&
          runtimeType == other.runtimeType &&
          n == other.n &&
          std == other.std;

  @override
  String toString() {
    return 'BOLLParam{n:$n, std:$std}';
  }
}

final class MACDParam {
  final int s;
  final int l;
  final int m;

  const MACDParam({required this.s, required this.l, required this.m});

  bool get isValid => l > 0 && s > 0 && l > s && m > 0;

  int get paramCount => math.max(l, s) + m;

  @override
  int get hashCode => s.hashCode ^ l.hashCode ^ m.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MACDParam &&
          runtimeType == other.runtimeType &&
          s == other.s &&
          l == other.l &&
          m == other.m;

  @override
  String toString() {
    return 'MACDParam{s:$s, l:$l, m:$s}';
  }
}

final class KDJParam {
  final int n;
  final int m1;
  final int m2;

  const KDJParam({required this.n, required this.m1, required this.m2});

  bool get isValid => n > 0 && m1 > 0 && m2 > 0;

  @override
  int get hashCode => n.hashCode ^ m1.hashCode ^ m2.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MACDParam &&
          runtimeType == other.runtimeType &&
          n == other.s &&
          m1 == other.l &&
          m2 == other.m;

  @override
  String toString() {
    return 'KDJParam{n:$n, m1:$m1, m2:$m2}';
  }
}
