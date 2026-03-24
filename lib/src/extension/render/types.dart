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

/// 绘制方向
enum DrawDirection {
  /// The draw flows from left to right.
  ltr,

  center,

  /// The draw flows from right to left.
  rtl;

  bool get isltr => this == ltr;
  bool get isCenter => this == center;
  bool get isrtl => this == rtl;
}

/// 线条类型
enum LineType {
  solid, // 实线
  dashed, // 虚线
  dotted; // 点线
}

/// Y轴对齐方式
enum YAxisAlign {
  top,
  center,
  bottom;

  double distributeOffset(double top, double bottom, double height) {
    assert(
      top < bottom && height <= bottom - top,
      'distributeOffset invalid parameter! $top, $bottom, $height',
    );

    return switch (this) {
      YAxisAlign.top => top,
      YAxisAlign.bottom => bottom - height,
      YAxisAlign.center => top + (bottom - top - height) / 2,
    };
  }
}
