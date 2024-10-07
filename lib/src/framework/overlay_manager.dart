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

import '../core/interface.dart';
import '../model/candle_req/candle_req.dart';
import '../overlay/export.dart';
import 'collection/sortable_hash_set.dart';
import 'common.dart';
import 'configuration.dart';
import 'logger.dart';
import 'overlay.dart';

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
    required this.drawBinding,
    ILogger? logger,
  }) {
    loggerDelegate = logger;
  }

  final IConfiguration configuration;
  final IDraw drawBinding;

  @override
  String get logTag => 'OverlayMgr';

  /// DrawType的Overlay对应DrawObject的构建生成器集合
  final Map<IDrawType, DrawObjectBuilder> _overlayBuilders = {
    DrawType.trendLine: TrendLineDrawObject.new,
    DrawType.crossLine: CrossLineDrawObject.new,
    DrawType.horizontalLine: HorizontalLineDrawObject.new,
    DrawType.verticalLine: VerticalLineDrawObject.new,
    DrawType.extendedTrendLine: ExtendedTrendLineDrawObject.new,
    DrawType.arrowLine: ArrowLineDrawObject.new,
    DrawType.rayLine: RayLineDrawObject.new,
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
      saveOverlayListConfig(isClean: true);
    }
    _instId = request.instId;
    final list = configuration.getOverlayListConfig(_instId);
    _overlayList = SortableHashSet.from(list);
  }

  /// 保存当前配置
  /// [isClean] 清理当前[_overlayList]和[_overlayToObjects]
  void saveOverlayListConfig({bool isClean = true}) {
    configuration.saveOverlayListConfig(_instId, _overlayList);
    if (isClean) {
      for (var overlay in _overlayList) {
        overlay.dispose();
      }
      _overlayList.clear();
    }
  }

  /// 通过[type]创建Overlay.
  /// 在Overlay未完成绘制时, 其line的配置使用crosshair.
  /// 设置第一个指针位置为[initialPosition]
  Overlay createOverlay(IDrawType type) {
    return Overlay(
      key: _instId,
      type: type,
      line: drawBinding.config.crosshair,
    )..setPointer(Point.pointer(0, drawBinding.initialPosition));
  }

  /// 每次都创建新的Object.
  DrawObject? createDrawObject(Overlay overlay) {
    logi('createDrawObject => $overlay');
    return _overlayBuilders[overlay.type]?.call(overlay);
  }

  /// 首先获取[overlay]内缓存的object, 如果为空, 则创建新的.
  DrawObject? getDrawObject(Overlay overlay) {
    return overlay.object ??= createDrawObject(overlay);
  }

  /// 添加新的overlay,
  bool addOverlay(Overlay overlay) {
    if (!_overlayList.contains(overlay)) {
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

  // @Deprecated('')
  // Overlay? hitTestOverlay(IDrawContext context, Offset position) {
  //   assert(position.isFinite, 'hitTestOverlay($position) position is invalid!');
  //   for (var overlay in _overlayList) {
  //     if (overlay.object?.hitTest(context, position) == true) {
  //       return overlay;
  //     }
  //   }
  //   return null;
  // }

  // @Deprecated('')
  // void drawOverlayList(IDrawContext context, Canvas canvas, Size size) {
  //   DrawObject? object;
  //   for (var overlay in _overlayList) {
  //     object = getDrawObject(overlay);
  //     if (object != null) {
  //       object.draw(context, canvas, size);
  //     }
  //   }
  // }
}
