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

part of 'overlay.dart';

/// [Overlay]管理
/// 主要负责:
/// 1. Overly持久化与加载
/// 2. 当KlineData的[CandleReq]切换时, 切换Overly配置
/// 3. 向DrawController提供待绘制的[Overlay]列表.
/// 4. HitTest列表管理
/// 5. 管理[IDrawType]对应的[DrawObjectBuilder]构造器
final class OverlayManager with KlineLog {
  OverlayManager({
    required this.configuration,
    ILogger? logger,
  }) {
    loggerDelegate = logger;
  }

  final IConfiguration configuration;

  @override
  String get logTag => 'OverlayMgr';

  /// DrawType的Overlay对应DrawObject的构建生成器集合
  final Map<IDrawType, DrawObjectBuilder> _overlayBuilders = {
    DrawType.trendLine: TrendLineDrawObject.new,
    DrawType.trendAngle: TrendAngleDrawObject.new,
    DrawType.crossLine: CrossLineDrawObject.new,
    DrawType.horizontalLine: HorizontalLineDrawObject.new,
    DrawType.horizontalRayLine: HorizontalRayLineDrawObject.new,
    DrawType.horizontalTrendLine: HorizontalTrendLineDrawObject.new,
    DrawType.verticalLine: VerticalLineDrawObject.new,
    DrawType.extendedTrendLine: ExtendedTrendLineDrawObject.new,
    DrawType.arrowLine: ArrowLineDrawObject.new,
    DrawType.rayLine: RayLineDrawObject.new,
    DrawType.priceLine: PriceLineDrawObject.new,
    // 多线
    DrawType.parallelChannel: ParalleChannelDrawObject.new,
    DrawType.rectangle: RectangleDrawObject.new,
    DrawType.fibRetracement: FibRetracementDrawObject.new,
    DrawType.fibExpansion: FibExpansionDrawObject.new,
    DrawType.fibFans: FibFansDrawObject.new,
  };

  Iterable<IDrawType>? _supportDrawTypes;
  Iterable<IDrawType> get supportDrawTypes {
    return _supportDrawTypes ??= _overlayBuilders.keys;
  }

  /// 自定义[IDrawType]构建器
  void registerOverlayDrawObjectBuilder(
    IDrawType type,
    DrawObjectBuilder builder,
  ) {
    _overlayBuilders[type] = builder;
    _supportDrawTypes = null;
  }

  /// 当前KlineData唯一标识
  String _instId = '';

  /// 当前[_instId]对应[Overlay]集合
  SortableHashSet<Overlay> _overlayList = SortableHashSet<Overlay>();
  Iterable<Overlay> get overlayList => _overlayList;

  bool get hasOverlay => _overlayList.isNotEmpty;

  /// KlineData数据切换回调
  void onChangeCandleRequest(CandleReq request) {
    if (request.instId.isEmpty || request.instId == _instId) return;
    logd('onChangeCandleRequest $_instId => ${request.instId}');
    if (_instId.isNotEmpty) {
      disposeSyncAllOverlay();
    }
    _instId = request.instId;
    final list = configuration.getOverlayListConfig(_instId);
    // TODO: 检查是否有匹配的[DrawObjectBuilder]
    for (var overlay in list) {
      addOverlay(overlay);
    }
    // _overlayList = SortableHashSet.from(list);
  }

  /// 释放所有Overlay并清理[_overlayList].
  /// [isStore] 是否保存当前OverlayList到本地.
  /// [isSync] 清理后是否同步清理本地缓存.
  void disposeSyncAllOverlay({bool isStore = true, bool isSync = false}) {
    if (isStore) configuration.saveOverlayListConfig(_instId, _overlayList);
    for (var overlay in _overlayList) {
      overlay.dispose();
    }
    _overlayList.clear();
    if (isSync) configuration.saveOverlayListConfig(_instId, _overlayList);
  }

  /// 清理当前所有的Overlay.
  void cleanAllOverlay() => disposeSyncAllOverlay(isStore: false, isSync: true);

  /// 通过[type]创建Overlay.
  /// 在Overlay未完成绘制时, 其line的配置使用crosshair.
  Overlay createOverlay(IDrawType type, LineConfig line) {
    // TODO: 考虑将object集成进来
    return Overlay(
      key: _instId,
      type: type,
      line: line,
    );
  }

  /// 首先获取[overlay]内缓存的object, 如果为空, 则创建新的.
  DrawObject? getDrawObject(Overlay overlay) {
    return overlay._object ??= _overlayBuilders[overlay.type]?.call(overlay);
  }

  /// 添加新的overlay,
  bool addOverlay(Overlay overlay) {
    final builder = _overlayBuilders[overlay.type];
    if (builder == null) return false;
    if (!_overlayList.contains(overlay)) {
      // 后续绑定object操作, 也绑定DrawConfig;
      // overlay.object
      final old = _overlayList.append(overlay);
      old?.dispose();
      return true;
    }
    return false;
  }

  bool removeOverlay(Overlay overlay) {
    overlay.dispose();
    return _overlayList.remove(overlay);
  }

  void reSort() => _overlayList.reSort();
}
