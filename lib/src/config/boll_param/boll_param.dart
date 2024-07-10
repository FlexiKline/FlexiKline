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
import 'package:equatable/equatable.dart';

import '../../framework/serializers.dart';

part 'boll_param.g.dart';

@CopyWith()
@FlexiParamSerializable
final class BOLLParam extends Equatable {
  final int n;
  final int std;

  const BOLLParam({required this.n, required this.std});

  bool isValid(int len) => n > 0 && n <= len && std > 0;

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

  factory BOLLParam.fromJson(Map<String, dynamic> json) =>
      _$BOLLParamFromJson(json);
  Map<String, dynamic> toJson() => _$BOLLParamToJson(this);

  @override
  List<Object?> get props => [n, std];
}
