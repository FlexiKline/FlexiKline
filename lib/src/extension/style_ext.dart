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

import 'package:flutter/painting.dart';

extension FlexiKlineTextStyleExt on TextStyle {
  double? get totalHeight {
    if (height != null && fontSize != null) {
      return fontSize! * height!;
    } else if (fontSize != null) {
      return fontSize!;
    }
    return null;
  }

  /// 确保文本颜色不为空
  TextStyle ensure(Color? themeTextColor) {
    if (color.isValid || themeTextColor.isInvalid) return this;
    return copyWith(color: themeTextColor);
  }
}

extension FlexiKlineColorExt on Color? {
  /// 是否有效
  bool get isValid => this != null && this!.a != 0;

  /// 是否无效
  bool get isInvalid => !isValid;

  /// 确保颜色不为空
  Color ensure(Color color) {
    if (isValid) return this!;
    return color;
  }

  /// 如果颜色为空, 返回默认颜色
  Color? or(Color? color) {
    if (isValid) return this;
    if (color.isValid) return color;
    return this;
  }
}

extension FlexiKlineBorderSideExt on BorderSide? {
  BorderSide? ensure(Color? borderColor) {
    if (this == null || this!.color.isValid || borderColor.isInvalid) return this;
    return this!.copyWith(color: borderColor);
  }
}
