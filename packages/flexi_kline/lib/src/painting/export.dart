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

/// 绘制构件层: 不依赖配置与框架, 只依赖 `dart:*` 与 `package:flutter/*`。
library;

export 'borders/anchored_border.dart';
export 'borders/bubble_border.dart';
export 'borders/gradient_rounded_rectangle_border.dart';
export 'foundation/paint_resource.dart';
export 'foundation/paint_resource_owner.dart';
export 'geometry/placement.dart';
export 'icons/shape_image.dart';
export 'painters/image_painter.dart';
export 'painters/image_style.dart';
export 'painters/label_painter.dart';
export 'painters/label_style.dart';
export 'painters/point_buffer.dart';
export 'painters/raw_image_span.dart';
export 'painters/text_layout_cache.dart';
export 'painters/tooltip_painter.dart';
