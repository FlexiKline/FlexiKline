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

/// 基线版本的 [compat.dart](compat.dart), 由 `tool/benchmark/overlay.sh --app` 在基线树里覆盖过去; 签名与它一致。
///
/// 当前树里它不被任何代码 import, 只随 app 一起被分析, 签名漂移时编译期就能发现。
library;

import 'package:flexi_kline/flexi_kline.dart';

/// 基线没有 `isDataPipelineIdle`; 它的合并与切换后的计算在调用内同步完成, 返回 true 即可。
bool isDataSettled(FlexiKlineController controller) => true;
