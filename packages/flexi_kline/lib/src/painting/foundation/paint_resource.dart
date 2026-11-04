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

/// 绘制对象跨帧持有的资源。
///
/// 由持有者登记(见 PaintResourceOwner): 声明变化时 [reset], 持有者销毁时 [dispose]。
abstract interface class PaintResource {
  /// 丢弃缓存内容, 对象本身保留可继续使用。
  void reset();

  /// 释放原生资源(如 TextPainter 持有的 ui.Paragraph)。之后不可再用。
  void dispose();
}
