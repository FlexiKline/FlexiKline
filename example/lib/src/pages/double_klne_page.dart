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

import 'package:example/src/theme/flexi_theme.dart';
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config.dart';
import '../providers/default_kline_config.dart';
import '../providers/instruments_provider.dart';

class DoubleKlinePage extends ConsumerStatefulWidget {
  const DoubleKlinePage({
    super.key,
    this.instId1 = 'BTC-USDT',
    this.instId2 = 'ETH-USDT',
  });

  final String instId1;
  final String instId2;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _DoubleKlinePageState();
}

class _DoubleKlinePageState extends ConsumerState<DoubleKlinePage> {
  late CandleReq req1;
  late CandleReq req2;
  late final FlexiKlineController controller1;
  late final FlexiKlineController controller2;
  late final DefaultFlexiKlineConfiguration configuration;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    final p1 = ref.read(instrumentsMgrProvider.notifier).getPrecision(
          widget.instId1,
        );
    final p2 = ref.read(instrumentsMgrProvider.notifier).getPrecision(
          widget.instId2,
        );
    req1 = CandleReq(
      instId: widget.instId1,
      bar: TimeBar.m15.bar,
      precision: p1 ?? 2,
      limit: 300,
    );
    req2 = CandleReq(
      instId: widget.instId2,
      bar: TimeBar.m15.bar,
      precision: p2 ?? 2,
      limit: 300,
    );

    configuration = DefaultFlexiKlineConfiguration(ref: ref);
    controller1 = FlexiKlineController(
      configuration: configuration,
      logger: LoggerImpl(
        tag: "DoubleKline1",
        debug: kDebugMode,
      ),
    );
    controller2 = FlexiKlineController(
      configuration: configuration,
      logger: LoggerImpl(
        tag: "DoubleKline2",
        debug: kDebugMode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    ref.listen(defaultKlineThemeProvider, (previous, next) {
      if (previous != next) {
        final config = configuration.getFlexiKlineConfig(next);
        controller1.updateFlexiKlineConfig(config);
        controller2.updateFlexiKlineConfig(config);
      }
    });
    return Container();
  }
}
