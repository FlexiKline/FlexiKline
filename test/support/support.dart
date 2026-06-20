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

/// 测试支撑 barrel：领域测试统一 `import '../support/support.dart';`
library;

export 'builders/controller_scenario.dart';
export 'builders/manager_scenario.dart';
export 'doubles/fake_kline_config.dart';
export 'doubles/fake_paint_context.dart';
export 'doubles/lifecycle_spy.dart';
export 'doubles/log_print_impl.dart';
export 'doubles/test_indicators.dart';
export 'fixtures/candle_factory.dart';
export 'fixtures/mock_candle_data.dart';
export 'generators/indicator_desc.dart';
export 'generators/slot_ops.dart';
export 'matchers/indicator_matchers.dart';
export 'property.dart';
