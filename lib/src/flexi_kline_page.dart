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

import 'package:flutter/widgets.dart';

import 'framework/configuration.dart';
import 'kline_controller.dart';

abstract interface class IFlexiKlinePage {
  FlexiKlineController get klineController;
}

mixin FlexiKlinePageMixin<T extends StatefulWidget> on State<T>
    implements IFlexiKlinePage {
  IFlexiKlineTheme get flexiTheme => klineController.theme;

  // @mustCallSuper
  // void didChangeFlexiTheme(IFlexiKlineTheme theme) {
  //   final config = klineController.configuration.getFlexiKlineConfig();
  //   klineController.updateFlexiKlineConfig(config);
  // }
}
