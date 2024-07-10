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

import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:equatable/equatable.dart';

import '../../framework/serializers.dart';

part 'macd_param.g.dart';

@CopyWith()
@FlexiParamSerializable
final class MACDParam extends Equatable {
  final int s;
  final int l;
  final int m;

  const MACDParam({required this.s, required this.l, required this.m});

  bool isValid(int len) {
    return l > 0 && s > 0 && l > s && m > 0 && paramCount <= len;
  }

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

  factory MACDParam.fromJson(Map<String, dynamic> json) =>
      _$MACDParamFromJson(json);
  Map<String, dynamic> toJson() => _$MACDParamToJson(this);

  @override
  List<Object?> get props => [s, l, m];
}
