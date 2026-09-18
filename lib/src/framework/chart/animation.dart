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

part of 'indicator.dart';

/// 为 [PaintObject] 提供 vsync, 使指标能直接用 `AnimationController` 及其全套设施
/// (`Tween` / `CurvedAnimation` / `TweenSequence` 等)。
///
/// ```dart
/// class TrendLinePaintObject extends ExternalPaintObject<TrendLineIndicator>
///     with TickerProviderPaintObjectMixin {
///   late final AnimationController _growth = AnimationController(
///     vsync: this,
///     duration: const Duration(milliseconds: 400),
///   );
///
///   @override
///   void loadBusinessData() => _growth.forward(from: 0);
///
///   @override
///   void dispose() {
///     _growth.dispose(); // 必须在 super 之前
///     super.dispose();
///   }
/// }
/// ```
///
/// vsync 归绘制对象自己, 不来自任何 Widget —— [Ticker] 的构造本就不需要 vsync, 于是手势层
/// State 重建、detector 切换、图表 Widget 出树都不影响已创建的动画。取舍见 `CONTEXT.md` 的
/// `Paint Object Animation Ownership`。
///
/// 与 Flutter 的 `TickerProviderStateMixin` 相比多做两件事:
///
/// 1. **tick 即重绘。** 每次 tick 后自动 [PaintContext.requestRepaint], 实现方无需在动画
///    listener 里手动标脏, 于是「动画在跑但画面不动」不会发生。
/// 2. **多一个静音源。** 除 `TickerMode` 的 `enabled`, 还看本对象是否在绘制树内:
///    [ExternalPaintObject] 一族 `keepAlive` 为 true, 出树只 detach 不 dispose, 那时必须
///    冻结, 否则每帧仍在请求重绘。
///
/// > [!warning]
/// > 静音是**冻结**而非暂停, 分两种情形: 已 tick 过再静音, 恢复后首帧的 elapsed 含整段静音
/// > 时长(短动画等于直接跳到完成, 入场动画通常正是期望行为); 尚未 tick 就静音(如在
/// > `initState` 里 `forward`, 那时还未 attach)则解除后从头跑。需要「恢复后重播」的指标自行
/// > 在 [PaintObject.didAttach] 里重启。
///
/// 动画帧走不带 `reset` 的重绘, 所以 [IPaintState.computeVisibleMinMax] 与命中判定都应按
/// **最终**形态给出, 跟随进度会让 Y 轴每帧抖动。`repeat()` 让 Ticker 常驻、整个 chart 图层
/// 按帧率重绘, 需自行评估开销。
///
/// `AnimationController` 的所有权仍在实现方: 本 mixin 只对残留 Ticker 做停止与释放兜底并打
/// 一条警告, 兜底管不到 controller 自身的 listener。
mixin TickerProviderPaintObjectMixin<T extends Indicator<IIndicatorKey>> on PaintObject<T> implements TickerProvider {
  Set<Ticker>? _tickers;

  /// Widget 层 `TickerMode` 策略的来源; 首次 [createTicker] 时懒订阅。
  ValueListenable<TickerModeData>? _tickerModeNotifier;

  TickerModeData get _tickerMode => _tickerModeNotifier?.value ?? TickerModeData.fallback;

  /// Widget 不可见或本对象不在绘制树内时冻结; `forceFrames` 是独立的一维, 不参与本值。
  bool get _effectiveMuted => !_tickerMode.enabled || !_attached;

  @override
  Ticker createTicker(TickerCallback onTick) {
    assert(!isDisposed, '$runtimeType.createTicker() 在 dispose 之后被调用。');
    // 懒订阅: 不用动画的对象零成本, 且 Ticker 在任何生命周期阶段创建都能读到此刻的策略。
    _tickerModeNotifier ??= context.tickerModeListenable..addListener(_updateTickers);

    final ticker = _PaintObjectTicker(
      (elapsed) {
        onTick(elapsed);
        context.requestRepaint();
      },
      this,
      debugLabel: kDebugMode ? 'created by ${describeIdentity(this)}' : null,
    );
    // 创建时就贴策略, 不是先跑一帧再补: 否则不可见时 forward() 会白跑一帧。
    ticker.muted = _effectiveMuted;
    ticker.forceFrames = _tickerMode.forceFrames;

    (_tickers ??= <Ticker>{}).add(ticker);
    return ticker;
  }

  /// 把当前策略贴到已发出的全部 Ticker 上; 对照 `TickerProviderStateMixin._updateTickers`。
  void _updateTickers() {
    final tickers = _tickers;
    if (tickers == null) return;
    final muted = _effectiveMuted;
    final forceFrames = _tickerMode.forceFrames;
    for (final ticker in tickers) {
      ticker.muted = muted;
      ticker.forceFrames = forceFrames;
    }
  }

  void _removeTicker(Ticker ticker) {
    _tickers?.remove(ticker);
  }

  @protected
  @mustCallSuper
  @override
  void didAttach() {
    super.didAttach();
    _updateTickers();
  }

  @protected
  @mustCallSuper
  @override
  void didDetach() {
    super.didDetach();
    _updateTickers();
  }

  @protected
  @mustCallSuper
  @override
  void dispose() {
    // 先摘下集合再遍历: Ticker.dispose 会回调 [_removeTicker], 置 null 后它是空操作。
    final tickers = _tickers;
    _tickers = null;
    if (tickers != null) {
      for (final ticker in tickers) {
        // 警告而非断言: 断言在 release 不生效, 会留下一条只在 release 走到、无法测试的分支。
        if (ticker.isActive) {
          logw('dispose 时仍有活跃 Ticker; 应先 dispose AnimationController 再调 super。');
        }
        ticker.stop(canceled: true);
        ticker.dispose();
      }
    }

    _tickerModeNotifier?.removeListener(_updateTickers);
    _tickerModeNotifier = null;
    super.dispose();
  }
}

/// [TickerProviderPaintObjectMixin] 发出的 Ticker: dispose 时把自己从创建者的集合中摘除。
class _PaintObjectTicker extends Ticker {
  _PaintObjectTicker(super.onTick, this._creator, {super.debugLabel});

  final TickerProviderPaintObjectMixin _creator;

  @override
  void dispose() {
    _creator._removeTicker(this);
    super.dispose();
  }
}
