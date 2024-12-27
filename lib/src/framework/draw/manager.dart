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
    final drawObjectbuilders = configuration.drawObjectBuilders;
    for (final MapEntry(key: type, value: builder)
        in drawObjectbuilders.entries) {
      registerDrawOverlayObjectBuilder(type, builder);
    }
  }

  final IConfiguration configuration;

  @override
  String get logTag => 'OverlayDrawObjectManager';

  /// DrawType的Overlay对应DrawObject的构建生成器集合
  final Map<IDrawType, DrawObjectBuilder> _overlayBuilders = {};

  Iterable<IDrawType>? _supportDrawTypes;
  Iterable<IDrawType> get supportDrawTypes {
    return _supportDrawTypes ??= _overlayBuilders.keys;
  }

  Map<String, Iterable<IDrawType>>? _supportDrawGroupTypes;
  Map<String, Iterable<IDrawType>> get supportDrawGroupTypes {
    if (_supportDrawGroupTypes == null || _supportDrawGroupTypes!.isEmpty) {
      final groupMap = <String, Set<IDrawType>>{};
      for (var type in supportDrawTypes) {
        final set = groupMap[type.groupId] ??= LinkedHashSet<IDrawType>(
          equals: (p0, p1) {
            return p0.groupId == p1.groupId &&
                p0.id == p1.id &&
                p0.steps == p1.steps;
          },
        );
        set.add(type);
      }
      _supportDrawGroupTypes = groupMap;
    }
    return _supportDrawGroupTypes!;
  }

  /// 自定义[IDrawType]构建器
  void registerDrawOverlayObjectBuilder(
    IDrawType type,
    DrawObjectBuilder builder,
  ) {
    _overlayBuilders[type] = builder;
    _supportDrawTypes = null;
    _supportDrawGroupTypes = null;
  }

  /// 当前KlineData唯一标识
  String _instId = '';

  /// 当前[_instId]对应[Overlay]集合
  final _overlayObjectList = SortableHashSet<DrawObject>();
  Iterable<DrawObject> get overlayObjectList => _overlayObjectList;
  Iterable<DrawObject> get overlayObjectReversedList {
    return _overlayObjectList.reversed;
  }

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
    final list = configuration.getDrawOverlayList(_instId);
    for (var overlay in list) {
      final object = generateDrawObject(overlay, config);
      if (object != null) {
        addDrawObject(object);
      }
    }
  }

  /// 将当前[Overlay]列表缓存到本地
  void saveOverlayListToLocal({bool isDispose = true}) {
    configuration.saveDrawOverlayList(
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
  DrawObject? createDrawObject(
    IDrawType type, {
    required DrawConfig drawConfig,
  }) {
    return generateDrawObject(
      Overlay(
        key: _instId,
        type: type,
        line: drawConfig.drawLine,
      ),
      drawConfig,
    );
  }

  DrawObject? generateDrawObject(Overlay overlay, DrawConfig config) {
    final builder = _overlayBuilders[overlay.type];
    if (builder == null) return null;
    return builder.call(overlay, config);
  }

  /// 添加新的[object].
  /// [replaceIfPresent] true: 如果[object]已存在替换之; 否则不处理.
  /// [addToTop] true: 添加[object]并保持在顶层绘制.
  void addDrawObject(
    DrawObject object, {
    bool replaceIfPresent = true,
    bool addToTop = false,
  }) {
    if (addToTop) moveToTop(object);
    final old = _overlayObjectList.append(
      object,
      replaceIfPresent: replaceIfPresent,
    );
    old?.dispose();
  }

  bool removeDrawObject(DrawObject object) {
    object.dispose();
    return _overlayObjectList.remove(object);
  }

  void resetObjectListSort() => _overlayObjectList.resetSort();

  void moveToTop(DrawObject object) {
    final last = _overlayObjectList.lastOrNull;
    if (last == object) return;
    object._overlay.zIndex = (last?.zIndex ?? drawObjectDefaultZIndex) + 1;
    resetObjectListSort();
  }

  void moveToBottom(DrawObject object) {
    final first = _overlayObjectList.firstOrNull;
    if (first == object) return;
    object._overlay.zIndex = (first?.zIndex ?? drawObjectDefaultZIndex) - 1;
    resetObjectListSort();
  }

  bool isOnTop(DrawObject<Overlay> object) {
    final last = _overlayObjectList.lastOrNull;
    return last == object;
  }

  bool isOnBottom(DrawObject<Overlay> object) {
    final first = _overlayObjectList.firstOrNull;
    return first == object;
  }
}
