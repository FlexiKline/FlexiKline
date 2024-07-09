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

part 'sar_param.g.dart';

@CopyWith()
@FlexiParamSerializable
final class SARParam extends Equatable {
  final double startAf;
  final double step;
  final double maxAf;

  const SARParam({
    this.startAf = 0.02,
    this.step = 0.02,
    this.maxAf = 0.2,
  });

  bool isValid(int len) => len > 1;

  @override
  String toString() {
    return 'SARParam(startAf:$startAf, step:$step, $maxAf)';
  }

  factory SARParam.fromJson(Map<String, dynamic> json) =>
      _$SARParamFromJson(json);
  Map<String, dynamic> toJson() => _$SARParamToJson(this);

  @override
  List<Object?> get props => [startAf, step, maxAf];
}
