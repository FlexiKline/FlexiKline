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

/// Flutter 画布绘制原语: 异形边框、带缓存的标签与图片绘制、代码绘制的小图标、跨帧资源管理。
///
/// 只依赖 Flutter。
library;

export 'src/borders/anchored_border.dart';
export 'src/borders/bubble_border.dart';
export 'src/borders/gradient_rounded_rectangle_border.dart';
export 'src/borders/shape_decoration.dart';
export 'src/foundation/paint_resource.dart';
export 'src/foundation/paint_resource_owner.dart';
export 'src/geometry/path_corner.dart' show PathCorner;
export 'src/geometry/placement.dart';
export 'src/icons/icon_shape.dart';
export 'src/icons/icon_shapes.dart';
export 'src/icons/shape_icon.dart';
export 'src/icons/shape_image.dart';
export 'src/icons/shape_image_provider.dart';
export 'src/painters/image_painter.dart';
export 'src/painters/image_style.dart';
export 'src/painters/label_painter.dart';
export 'src/painters/label_style.dart';
export 'src/painters/point_buffer.dart';
export 'src/painters/raw_image_span.dart';
export 'src/painters/text_layout_cache.dart';
export 'src/painters/tooltip_painter.dart';
