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

/// 与 K 线无关的绘制原语: 异形边框、带缓存的标签与图片绘制、代码绘制的小图标、跨帧资源管理。
///
/// 只依赖 Flutter, 不需要 K 线时 import 本入口即可; `flexi_kline.dart` 已包含这里的全部导出。
library;

export 'src/painting/export.dart';
