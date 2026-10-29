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

/// 自定义 matcher：断言即规格。
library;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter_test/flutter_test.dart';

/// 断言 key 已在主区激活
Matcher isActivatedInMain(IndicatorPaintObjectManager m) => _ActivatedInMainMatcher(m);

class _ActivatedInMainMatcher extends Matcher {
  _ActivatedInMainMatcher(this._m);
  final IndicatorPaintObjectManager _m;

  @override
  bool matches(Object? item, Map matchState) => _m.mainIndicatorKeys.contains(item);

  @override
  Description describe(Description d) => d.add('activated in main');

  @override
  Description describeMismatch(Object? item, Description d, Map matchState, bool verbose) {
    return d.add('$item not found in ${_m.mainIndicatorKeys.toList()}');
  }
}
