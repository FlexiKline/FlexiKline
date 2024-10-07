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

import '../../utils/vector_util.dart';
import '../../framework/serializers.dart';

part 'draw_params.g.dart';

@CopyWith()
@FlexiConfigSerializable
class DrawParams {
  const DrawParams({
    this.arrowsRadians = pi30,
    this.arrowsLen = 16.0,
  });

  /// 箭头相对于基线的角度.
  final double arrowsRadians;

  /// 箭头长度
  final double arrowsLen;

  factory DrawParams.fromJson(Map<String, dynamic> json) =>
      _$DrawParamsFromJson(json);

  Map<String, dynamic> toJson() => _$DrawParamsToJson(this);
}
