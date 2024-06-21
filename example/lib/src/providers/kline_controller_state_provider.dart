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
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final klineStateProvider = ChangeNotifierProvider.autoDispose
    .family<KlineStateNotifier, FlexiKlineController>(
  (ref, controller) => KlineStateNotifier(ref, controller),
  name: 'klineState',
);

class KlineStateNotifier extends ChangeNotifier {
  KlineStateNotifier(
    this.ref,
    this.controller,
  );

  final Ref ref;
  final FlexiKlineController controller;

  Set<ValueKey> get supportMainIndicatorKeys =>
      controller.supportMainIndicatorKeys;
  Set<ValueKey> get supportSubIndicatorKeys =>
      controller.supportSubIndicatorKeys;
  Set<ValueKey> get mainIndicatorKeys => controller.mainIndicatorKeys;
  Set<ValueKey> get subIndicatorKeys => controller.subIndicatorKeys;

  void onTapMainIndicator(ValueKey key) {
    if (controller.mainIndicatorKeys.contains(key)) {
      controller.delIndicatorInMain(key);
    } else {
      controller.addIndicatorInMain(key);
    }
    notifyListeners();
  }

  void onTapSubIndicator(ValueKey key) {
    if (controller.subIndicatorKeys.contains(key)) {
      controller.delIndicatorInSub(key);
    } else {
      controller.addIndicatorInSub(key);
    }
    notifyListeners();
  }

  /// 蜡烛图中是否展示最新价
  bool get isShowLatestPrice {
    return controller.indicatorsConfig.candle.latest.show;
  }

  /// 设置蜡烛图中是否展示最新价
  void setShowLatestPrice(bool isShow) {
    if (isShow == isShowLatestPrice) return;
    controller.indicatorsConfig = controller.indicatorsConfig.copyWith(
      candle: controller.indicatorsConfig.candle.copyWith(
        latest: controller.indicatorsConfig.candle.latest.copyWith(
          show: isShow,
        ),
      ),
    );
    notifyListeners();
  }

  /// 蜡烛图中是否展示最新价
  bool get isShowCountDown {
    return controller.indicatorsConfig.candle.showCountDown;
  }

  /// 设置蜡烛图中是否展示最新价
  void setShowCountDown(bool isShow) {
    if (isShow == isShowCountDown) return;
    controller.indicatorsConfig = controller.indicatorsConfig.copyWith(
      candle: controller.indicatorsConfig.candle.copyWith(
        showCountDown: isShow,
      ),
    );
    notifyListeners();
  }

  /// 是否展示Y轴刻度
  bool get isShowYAxisTick {
    return controller.settingConfig.showYAxisTick;
  }

  /// 设置是否展示Y轴坐标刻度
  void setShowYAxisTick(bool isShow) {
    if (isShow == isShowYAxisTick) return;
    controller.settingConfig = controller.settingConfig.copyWith(
      showYAxisTick: isShow,
    );
    notifyListeners();
  }
}
