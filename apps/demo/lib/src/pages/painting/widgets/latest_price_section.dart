import 'dart:async';
import 'dart:math' as math;

import 'package:flexi_formatter/flexi_formatter.dart';
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/material.dart';

import '../../../config/my_kline_config.dart';
import '../../../config/my_kline_indicator_config.dart';
import 'section.dart';

/// 最新价标签 + 倒计时(最新蜡烛在视区内): 价格每秒跳动、涨跌换色, 倒计时到整分钟。
///
/// 样式取自 [CandleIndicator.inViewPriceMark] 与 [CandleIndicator.countdown] 的配置(demo K 线页同一份)。
class LatestPriceSection extends StatelessWidget {
  const LatestPriceSection(this.configuration, this.indicatorConfig, {super.key});

  final MyKlineConfig configuration;
  final MyKlineIndicatorConfig indicatorConfig;

  @override
  Widget build(BuildContext context) => PaintingSection(
    title: '最新价与倒计时',
    caption: '倒计时与最新价同宽(minWidth 撑开, bounds 宽度封顶); 边框样式接缝只画一条线, 蜡烛色边框整框描一圈无分隔线。',
    height: 150,
    create: () => _LatestPricePainter(configuration, indicatorConfig),
  );
}

/// 一种样式解析结果: 线色、最新价与倒计时样式, 以及包住两者的外框(为 null 时不画)。
///
/// [seam] 是倒计时上移的量: 两者都描边时上移一个边框宽度, 接缝只画一条线。
typedef _Resolved = ({Color line, LabelStyle latest, LabelStyle countdown, ShapeBorder? frame, double seam});

typedef _LatestStyle = ({String name, _Resolved Function(IFlexiKlineTheme theme, Color candle) resolve});

class _LatestPricePainter extends SectionPainter {
  _LatestPricePainter(super.configuration, super.indicatorConfig) {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _change = (_random.nextDouble() - 0.5) * 2;
      _price += _change;
      markNeedsPaint();
    });
  }

  late final _latest = [for (final _ in _styles) own(LabelPainter())];
  late final _countdown = [for (final _ in _styles) own(LabelPainter())];
  late final _names = own(LabelPainter(capacity: 3));

  final _random = math.Random(7);
  late final Timer _timer;
  double _price = 1234.5;
  double _change = 0;

  static const _nameConfig = TextAreaConfig(style: TextStyle(fontSize: 10));

  late final _candle = indicatorConfig.candle;
  late final _mark = _candle.inViewPriceMark;
  late final _borderWidth = _mark.text.border?.width ?? 0;

  /// 两者上下拼接: 最新价只留上圆角, 倒计时只留下圆角; 边框宽度沿用最新价配置, 颜色由主题或涨跌色兜底。
  TextAreaConfig _top() => _mark.text.copyWith(
    borderRadius: _mark.text.borderRadius?.copyWith(bottomLeft: Radius.zero, bottomRight: Radius.zero),
  );

  TextAreaConfig _bottom() => _candle.countdown.copyWith(
    border: _mark.text.border,
    borderRadius: _mark.text.borderRadius?.copyWith(topLeft: Radius.zero, topRight: Radius.zero),
  );

  // 每种样式各持一份配置实例: toLabelStyle 按实例单项记忆, 共用实例而颜色不同会每帧重算。
  late final _solidLatest = _top();
  late final _solidCountdown = _bottom().copyWith(
    style: _candle.countdown.style.copyWith(color: Colors.black87),
    backgroundColor: Colors.white,
  );
  late final _borderLatest = _top(), _borderCountdown = _bottom();

  /// 两块都不描边(边框透明且不给兜底色), 由 [_frame] 沿合并矩形描一圈, 中间没有分隔线。
  late final _frameLatest = _top();
  late final _frameCountdown = _bottom().copyWith(textAlign: TextAlign.end);
  late final _frame = _mark.text.copyWith();

  late final List<_LatestStyle> _styles = [
    (
      name: '蜡烛色背景',
      resolve: (theme, candle) => (
        line: candle,
        latest: _solidLatest.toLabelStyle(textColor: Colors.white, backgroundColor: candle),
        countdown: _solidCountdown.toLabelStyle(),
        frame: null,
        seam: 0,
      ),
    ),
    (
      name: '边框',
      resolve: (theme, _) => (
        line: theme.markLineColor,
        latest: _borderLatest.toLabelStyle(
          textColor: theme.textColor,
          backgroundColor: theme.latestPriceBg,
          borderColor: theme.markLineColor,
        ),
        countdown: _borderCountdown.toLabelStyle(
          textColor: theme.textColor,
          backgroundColor: theme.countdownBg,
          borderColor: theme.markLineColor,
        ),
        frame: null,
        seam: _borderWidth,
      ),
    ),
    (
      name: '蜡烛色边框',
      resolve: (theme, candle) => (
        line: candle,
        latest: _frameLatest.toLabelStyle(textColor: theme.textColor, backgroundColor: theme.latestPriceBg),
        countdown: _frameCountdown.toLabelStyle(textColor: theme.textColor, backgroundColor: theme.countdownBg),
        frame: _frame.toLabelStyle(borderColor: candle).decoration?.shape,
        seam: 0,
      ),
    ),
  ];

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day, now.hour, now.minute + 1);
    final candle = _change >= 0 ? theme.longColor : theme.shortColor;
    final price = _price;

    final rowHeight = size.height / _styles.length;
    for (final (i, style) in _styles.indexed) {
      final y = rowHeight * i + 12;
      final resolved = style.resolve(theme, candle);
      canvas.drawLineByConfig(
        Path()
          ..moveTo(0, y)
          ..lineTo(size.width, y),
        _mark.line,
        themeColor: resolved.line,
      );

      final latest = _latest[i].paint(
        canvas,
        price,
        build: () => price.toStringAsFixed(2),
        style: resolved.latest,
        anchor: Offset(size.width - _mark.spacing, y),
        align: Alignment.centerRight,
      );
      final countdown = _countdown[i].paint(
        canvas,
        next.difference(now).inSeconds,
        build: () => next.diffAsCountdown(now),
        style: resolved.countdown,
        anchor: latest.bottomRight.translate(0, -resolved.seam),
        align: Alignment.topRight,
        bounds: Rect.fromLTRB(latest.left, latest.bottom - resolved.seam, latest.right, double.infinity),
        minWidth: latest.width,
      );
      resolved.frame?.paint(canvas, latest.expandToInclude(countdown));

      _names.paint(
        canvas,
        style.name,
        style: _nameConfig.toLabelStyle(textColor: theme.ticksTextColor),
        anchor: Offset(0, y - 2),
        align: Alignment.bottomLeft,
      );
    }
  }
}
