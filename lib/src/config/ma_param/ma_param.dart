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
import '../tips_config/tips_config.dart';

part 'ma_param.g.dart';

@CopyWith()
@FlexiParamSerializable
final class MaParam extends Equatable {
  final int count;
  final TipsConfig tips;

  const MaParam({
    required this.count,
    required this.tips,
  });

  static int? getMaxCountByList(List<MaParam> list) {
    if (list.isEmpty) return null;
    int? count;
    for (var param in list) {
      count ??= param.count;
      count = param.count > count ? param.count : count;
    }
    return count;
  }

  static int? getMinCountByList(List<MaParam> list) {
    if (list.isEmpty) return null;
    int? count;
    for (var param in list) {
      count ??= param.count;
      count = param.count < count ? param.count : count;
    }
    return count;
  }

  factory MaParam.fromJson(Map<String, dynamic> json) =>
      _$MaParamFromJson(json);
  Map<String, dynamic> toJson() => _$MaParamToJson(this);

  @override
  List<Object?> get props => [count];
}
