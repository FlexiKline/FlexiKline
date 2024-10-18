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

/// [OverlayObject]管理
/// 主要负责:
/// 1. Overly持久化与加载
/// 2. 当KlineData的[CandleReq]切换时, 切换Overly配置
/// 3. 向DrawController提供待绘制的[Overlay]列表.
/// 4. HitTest列表管理
/// 5. 管理[IDrawType]对应的[DrawObjectBuilder]构造器
final class OverlayDrawObjectManager with KlineLog {
  OverlayDrawObjectManager({
    required this.configuration,
    ILogger? logger,
  }) {
    loggerDelegate = logger;
  }

  final IConfiguration configuration;

  @override
  String get logTag => 'OverlayDrawObjectManager';

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
  void registerDrawOverlayObjectBuilder(
    IDrawType type,
    DrawObjectBuilder builder,
  ) {
    _overlayBuilders[type] = builder;
    _supportDrawTypes = null;
  }

  /// 当前KlineData唯一标识
  String _instId = '';

  /// 当前[_instId]对应[Overlay]集合
  final _overlayObjectList = SortableHashSet<DrawObject>();
  Iterable<DrawObject> get overlayObjectList => _overlayObjectList;

  bool get hasObject => _overlayObjectList.isNotEmpty;

  /// KlineData数据切换回调
  void onChangeCandleRequest(CandleReq request, DrawConfig config) {
    if (request.instId.isEmpty || request.instId == _instId) return;
    logd('onChangeCandleRequest $_instId => ${request.instId}');
    // 缓存上一次OverlayObject到本地.
    if (_instId.isNotEmpty && hasObject) {
      saveOverlayListToLocal();
    }
    // 加载新的OverlayObject.
    _overlayObjectList.clear();
    _instId = request.instId;
    final list = configuration.getOverlayListConfig(_instId);
    for (var overlay in list) {
      final object = createDrawObject(overlay: overlay, config: config);
      if (object != null) {
        addDrawObject(object);
      }
    }
  }

  /// 将当前[Overlay]列表缓存到本地
  void saveOverlayListToLocal({bool isDispose = true}) {
    configuration.saveOverlayListConfig(
      _instId,
      _overlayObjectList.map((obj) {
        if (isDispose) obj.dispose();
        return obj._overlay;
      }),
    );
    _overlayObjectList.clear();
  }

  void dispose() {
    saveOverlayListToLocal();
  }

  /// 清理当前所有的Overlay.
  void cleanAllDrawObject() {
    for (var obj in _overlayObjectList) {
      obj.dispose();
    }
    _overlayObjectList.clear();
    saveOverlayListToLocal(isDispose: false);
  }

  /// 通过[type]创建Overlay.
  /// 在Overlay未完成绘制时, 其line的配置使用crosshair.
  DrawObject? createDrawObject({
    IDrawType? type,
    Overlay? overlay,
    required DrawConfig config,
  }) {
    if (overlay == null && type == null) return null;
    overlay ??= Overlay(key: _instId, type: type!, line: config.drawLine);

    final builder = _overlayBuilders[overlay.type];
    if (builder == null) return null;
    return builder.call(overlay, config);
  }

  /// 添加新的overlay,
  void addDrawObject(DrawObject object) {
    final old = _overlayObjectList.append(object);
    old?.dispose();
  }

  bool removeDrawObject(DrawObject object) {
    object.dispose();
    return _overlayObjectList.remove(object);
  }

  void reSort() => _overlayObjectList.reSort();
}
