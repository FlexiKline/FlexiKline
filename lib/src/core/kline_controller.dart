import 'dart:ui';

import 'package:kline/src/core/base_controller.dart';
import 'package:kline/src/model/candle_model/candle_model.dart';

import 'export.dart';

class KlineController with CandleBindings {
  KlineController({
    bool isDebug = false,
  });
}
