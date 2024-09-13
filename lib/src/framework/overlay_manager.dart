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

import 'dart:ui';

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
    DrawType.horizontalLine: HorizontalLineDrawObject.new,
  };

  Iterable<IDrawType>? _supportDrawTypes;
  Iterable<IDrawType> get supportDrawTypes {
    return _supportDrawTypes ??= _overlayBuilders.keys;
  }

  /// 自定义[IDrawType]构建器
  void customOverlayDrawObjectBuilder(
    IDrawType type,
    DrawObjectBuilder builder,
  ) {
    _overlayBuilders[type] = builder;
    _supportDrawTypes = null;
  }

  /// 当前KlineData唯一标识
  String _instId = '';

  /// 缓存[Overlay] 对应 [DrawObject]集合
  final _overlayToObjects = <Overlay, DrawObject>{};

  /// 当前[_instId]对应[Overlay]集合
  SortableHashSet<Overlay> _overlayList = SortableHashSet<Overlay>();
  Iterable<Overlay> get overlayList => _overlayList;

  /// KlineData数据切换回调
  void switchCandleRequest(CandleReq request) {
    if (request.instId.isEmpty || request.instId == _instId) return;
    logd('switchCandleRequest $_instId => ${request.instId}');
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
      _overlayList.clear();
      _overlayToObjects.clear();
    }
  }

  DrawObject? createDrawObject(Overlay overlay) {
    final object = _overlayBuilders[overlay.type]?.call(overlay);
    if (object != null) _overlayToObjects[overlay] = object;
    return object;
  }

  DrawObject? getDrawObject(Overlay overlay) {
    DrawObject? object = _overlayToObjects[overlay];
    object ??= createDrawObject(overlay);
    return object;
  }

  bool addOverlay(Overlay overlay) => _overlayList.add(overlay);

  bool removeOverlay(Overlay overlay) {
    final object = _overlayToObjects.remove(overlay);
    object?.dispose();
    return _overlayList.remove(overlay) || object != null;
  }

  Overlay? hitTestOverlay(Offset position) {}
}
