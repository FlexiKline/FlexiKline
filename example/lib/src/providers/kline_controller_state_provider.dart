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

  List<TimeBar> preferTimeBarList = [
    TimeBar.m15,
    TimeBar.H1,
    TimeBar.H4,
    TimeBar.D1,
  ];

  final List<TimeBar> allTimeBarList = TimeBar.values;

  TimeBar? _currentTimeBar;
  TimeBar? get currentTimeBar {
    return _currentTimeBar ?? controller.curKlineData.req.timeBar;
  }

  bool get isPreferTimeBar => preferTimeBarList.contains(currentTimeBar);

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

  void setTimeBar(TimeBar bar) {
    _currentTimeBar = bar;
    notifyListeners();
  }
}

final timeBarProvider = StateProvider.autoDispose
    .family<TimeBar?, FlexiKlineController>((ref, controller) {
  return ref.watch(
    klineStateProvider(controller).select((state) => state.currentTimeBar),
  );
});
