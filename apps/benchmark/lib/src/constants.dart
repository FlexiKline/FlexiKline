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

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';

/// 默认品种。
const benchSpec = KlineSpec(symbol: 'DEVICE-BENCH', interval: FlexiTimeInterval(1, TimeUnit.minute));

/// 切换场景的另一个品种: 与 [benchSpec] 来回切换, 模拟切币对。
const benchAltSpec = KlineSpec(symbol: 'DEVICE-BENCH-ALT', interval: FlexiTimeInterval(1, TimeUnit.minute));

/// 初始蜡烛根数。
const benchCandleCount = 2000;

/// 切换场景里 [benchAltSpec] 的根数。
const benchAltCandleCount = 5000;
