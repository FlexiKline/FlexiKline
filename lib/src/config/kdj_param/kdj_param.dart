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

import 'package:copy_with_extension/copy_with_extension.dart';

import '../../framework/serializers.dart';

part 'kdj_param.g.dart';

@CopyWith()
@FlexiParamSerializable
final class KDJParam {
  final int n;
  final int m1;
  final int m2;

  const KDJParam({required this.n, required this.m1, required this.m2});

  bool isValid(int len) => n > 0 && n <= len && m1 > 0 && m2 > 0;

  @override
  int get hashCode => n.hashCode ^ m1.hashCode ^ m2.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KDJParam &&
          runtimeType == other.runtimeType &&
          n == other.n &&
          m1 == other.m1 &&
          m2 == other.m2;

  @override
  String toString() {
    return 'KDJParam{n:$n, m1:$m1, m2:$m2}';
  }

  factory KDJParam.fromJson(Map<String, dynamic> json) =>
      _$KDJParamFromJson(json);
  Map<String, dynamic> toJson() => _$KDJParamToJson(this);
}
