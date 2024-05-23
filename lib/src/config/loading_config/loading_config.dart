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
import 'package:flutter/material.dart';

import '../../framework/serializers.dart';

part 'loading_config.g.dart';

@CopyWith()
@FlexiConfigSerializable
class LoadingConfig {
  const LoadingConfig({
    this.size = 24,
    this.strokeWidth = 4,
    this.background = const Color(0xFFECECEC),
    this.valueColor = Colors.black,
  });
  final double size;
  final double strokeWidth;
  final Color background;
  final Color valueColor;

  factory LoadingConfig.fromJson(Map<String, dynamic> json) =>
      _$LoadingConfigFromJson(json);

  Map<String, dynamic> toJson() => _$LoadingConfigToJson(this);
}
