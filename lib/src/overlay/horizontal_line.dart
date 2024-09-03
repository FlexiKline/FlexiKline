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

import 'dart:ui';

import '../core/export.dart';
import '../framework/export.dart';

class HorizontalLine extends Overlay {
  HorizontalLine({
    required super.key,
    required super.zIndex,
    required super.lock,
    required super.visible,
    required super.mode,
    required super.line,
  }) : super(type: DrawType.horizontalLine);

  @override
  HorizontalLineDrawObject createDrawObject() => HorizontalLineDrawObject(this);
}

class HorizontalLineDrawObject extends DrawObject<HorizontalLine> {
  HorizontalLineDrawObject(HorizontalLine overlay) : super(overlay: overlay);

  @override
  void drawOverlay(Canvas canvas, Size size) {}
}
