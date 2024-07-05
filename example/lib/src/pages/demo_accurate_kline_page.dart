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
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

import '../config.dart';
import '../providers/default_kline_config.dart';
import '../repo/mock.dart';
import 'components/flexi_kline_mark_view.dart';

class AccurateKlineDemoPage extends ConsumerStatefulWidget {
  const AccurateKlineDemoPage({
    super.key,
    this.isAlonePage = false,
    this.useAccurate = false,
    this.count,
  });

  final bool isAlonePage;
  final bool useAccurate;
  final int? count;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _AccurateKlinePageState();
}

class _AccurateKlinePageState extends ConsumerState<AccurateKlineDemoPage> {
  late final FlexiKlineController controller;
  late final DefaultFlexiKlineConfiguration configuration;

  late CandleReq req;

  final logger = LogPrintImpl(
    debug: kDebugMode,
    tag: 'Demo',
  );

  @override
  void initState() {
    super.initState();
    req = CandleReq(
      instId: 'SATS-USDT',
      bar: TimeBar.H1.bar,
      precision: widget.useAccurate ? 22 : 4,
      displayName: 'Sats',
    );
    configuration = DefaultFlexiKlineConfiguration(ref: ref);
    controller = FlexiKlineController(
      configuration: configuration,
      logger: logger,
    );

    if (widget.useAccurate) {
      controller.computeMode = ComputeMode.accurate;
    }

    // controller.onCrossCustomTooltip = onCrossCustomTooltip;

    controller.onLoadMoreCandles = loadMoreCandles;

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      initKlineData(req);
    });
  }

  /// 初始化加载K线蜡烛数据.
  Future<void> initKlineData(CandleReq request) async {
    controller.switchKlineData(request);

    List<CandleModel> list;
    if (widget.useAccurate) {
      list = await genLocalMinusculeCandleList(count: widget.count);
    } else {
      list = await genLocalCandleList(count: widget.count);
    }

    await controller.updateKlineData(request, list);
  }

  Future<void> loadMoreCandles(CandleReq request) async {
    SmartDialog.showToast('This is a simulation operation!');
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isAlonePage) {
      return Container();
    } else {
      return _buildKlineView(context);
    }
  }

  Widget _buildKlineView(BuildContext context) {
    return FlexiKlineWidget(
      key: const ValueKey('accurateKline'),
      controller: controller,
      mainBackgroundView: FlexiKlineMarkView(
        margin: EdgeInsetsDirectional.only(bottom: 10.r, start: 10.r),
      ),
    );
  }
}
