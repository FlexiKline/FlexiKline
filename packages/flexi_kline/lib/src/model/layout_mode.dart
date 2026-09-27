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

/// FlexiKline 的布局模式，决定画布尺寸来源。
enum FlexiLayoutMode {
  /// 自适应模式（默认）：宽度跟随父约束，高度由主区配置或拖拽控制。
  ///
  /// 新增副区指标时，总高度增长，主区不被压缩。
  adapt,

  /// 固定模式：画布尺寸完全固定（横屏/全屏）。
  ///
  /// 新增副区指标时，总高度不变，主区与副区在固定高度内重新分配。
  /// 父约束无限时，需通过 `initialFixedSize` 或 `setFixedLayoutMode` 提供尺寸。
  fixed,
}
