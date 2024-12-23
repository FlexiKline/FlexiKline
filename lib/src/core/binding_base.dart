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

part of 'core.dart';

abstract class KlineBindingBase
    with KlineLog
    implements ISetting, IPaintContext, IDrawContext {
  final IConfiguration configuration;

  /// 对于Kline的操作是否自动保存到本地配置中.
  /// 包括: dispose; 增删指标; 调整参数等等.
  final bool autoSave;

  /// klineData数据缓存容量
  /// 一个FlexiKlineController允许最多维护的KlineData个数.
  final int? klineDataCacheCapacity;

  /// 指标绘制对象管理
  final IndicatorPaintObjectManager _paintObjectManager;

  KlineBindingBase({
    required this.configuration,
    this.autoSave = true,
    ILogger? logger,
    this.klineDataCacheCapacity,
  }) : _paintObjectManager = IndicatorPaintObjectManager(
          configuration: configuration,
          logger: logger,
        ) {
    logd("constrouct");
    loggerDelegate = logger;
    // initFlexiKlineConfig();
    init();
  }

  @protected
  @mustCallSuper
  void init() {
    logd("init base");
  }

  @protected
  @mustCallSuper
  void initState() {
    logd("initState base");
  }

  @protected
  @mustCallSuper
  void dispose() {
    logd("dispose base");
    _paintObjectManager.dispose();
    if (autoSave) storeFlexiKlineConfig();
  }

  KlineBindingBase get instance => this;

  T getInstance<T extends KlineBindingBase>(T instance) {
    return instance;
  }
}

/// KlineController内部扩展
extension on KlineBindingBase {
  MainPaintObject get mainPaintObject {
    return _paintObjectManager.mainPaintObject;
  }

  TimeBasePaintObject get timePaintObject {
    return _paintObjectManager.timePaintObject;
  }

  Iterable<PaintObject> get subPaintObjects {
    return _paintObjectManager.subPaintObjects;
  }
}

/// Kline状态通知
class KlineStateNotifier<T> extends ValueNotifier<T> {
  KlineStateNotifier(super.value);

  @override
  void notifyListeners() {
    super.notifyListeners();
  }

  void updateValue(T val) {
    value = val;
    super.notifyListeners();
  }
}
