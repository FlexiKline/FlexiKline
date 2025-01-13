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

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter_test/flutter_test.dart';

import 'base/test_flexi_kline_configuration.dart';

void main() {
  TestFlexiKlineConfiguration configuration = TestFlexiKlineConfiguration();
  late FlexiKlineConfig flexiKlineConfig;
  setUp(() {
    flexiKlineConfig = configuration.generateFlexiKlineConfig();
    // flexiKlineConfig.main.add(IndicatorType.candle);
    // flexiKlineConfig.main.add(IndicatorType.volume);

    // flexiKlineConfig.sub.add(IndicatorType.maVol);
    // flexiKlineConfig.sub.add(IndicatorType.sar);

    // flexiKlineConfig.init();
  });

  // test('copywith indicator', () {
  //   final ma = flexiKlineConfig.indicators.ma;
  //   print(ma.toJson());

  //   final copyMa = ma.copyWith();
  //   print(copyMa.toJson());
  // });

  // test('copywith multi indicator', () {
  //   final main = flexiKlineConfig.mainIndicator;
  //   print(main.toJson());

  //   print('---------------');
  //   final copyMain = main.copyWith();
  //   print(copyMain.toJson());
  // });
}
