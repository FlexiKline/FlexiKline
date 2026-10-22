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

/// 两个版本 API 差异的唯一适配点。
///
/// `tool/benchmark/overlay.sh --app` 在基线树里用同目录的 `compat_baseline.dart` 覆盖本文件;
/// 每个差异一个函数并注明引入它的版本, 两份文件的签名必须一致, 场景代码只经这里碰版本差异。
library;

import 'package:flexi_kline/flexi_kline.dart';

/// 数据变更已完全生效: 没有待合并的批次与待计算的区间(2.6.1 起)。
bool isDataSettled(FlexiKlineController controller) => controller.isDataPipelineIdle;
