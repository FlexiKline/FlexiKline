import 'dart:ui';

import '../../config/line_config/line_config.dart';
import 'common.dart';

/// Came from [flutter_path_drawing](https://github.com/dnfield/flutter_path_drawing) library.
/// Creates a new path that is drawn from the segments of `source`.
///
/// Dash intervals are controled by the `dashArray` - see [CircularIntervalList]
/// for examples.
///
/// `dashOffset` specifies an initial starting point for the dashing.
///
/// Passing a `source` that is an empty path will return an empty path.
Path dashPath(
  Path source, {
  required CircularIntervalList<double> dashArray,
  DashOffset? dashOffset,
}) {
  assert(dashArray != null); // ignore: unnecessary_null_comparison

  dashOffset = dashOffset ?? const DashOffset.absolute(0);
  // TODO(imaNNeo): Is there some way to determine how much of a path would be visible today?

  final dest = Path();
  for (final metric in source.computeMetrics()) {
    var distance = dashOffset._calculate(metric.length);
    var draw = true;
    while (distance < metric.length) {
      final len = dashArray.next;
      if (draw) {
        dest.addPath(metric.extractPath(distance, distance + len), Offset.zero);
      }
      distance += len;
      draw = !draw;
    }
  }

  return dest;
}

enum _DashOffsetType { absolute, percentage }

/// Specifies the starting position of a dash array on a path, either as a
/// percentage or absolute value.
///
/// The internal value will be guaranteed to not be null.
class DashOffset {
  /// Create a DashOffset that will be measured as a percentage of the length
  /// of the segment being dashed.
  ///
  /// `percentage` will be clamped between 0.0 and 1.0.
  DashOffset.percentage(double percentage)
      : _rawVal = percentage.clamp(0.0, 1.0),
        _dashOffsetType = _DashOffsetType.percentage;

  /// Create a DashOffset that will be measured in terms of absolute pixels
  /// along the length of a [Path] segment.
  const DashOffset.absolute(double start)
      : _rawVal = start,
        _dashOffsetType = _DashOffsetType.absolute;

  final double _rawVal;
  final _DashOffsetType _dashOffsetType;

  double _calculate(double length) {
    return _dashOffsetType == _DashOffsetType.absolute
        ? _rawVal
        : length * _rawVal;
  }
}

/// A circular array of dash offsets and lengths.
///
/// For example, the array `[5, 10]` would result in dashes 5 pixels long
/// followed by blank spaces 10 pixels long.  The array `[5, 10, 5]` would
/// result in a 5 pixel dash, a 10 pixel gap, a 5 pixel dash, a 5 pixel gap,
/// a 10 pixel dash, etc.
///
/// Note that this does not quite conform to an [Iterable<T>], because it does
/// not have a moveNext.
class CircularIntervalList<T> {
  CircularIntervalList(this._values);

  final List<T> _values;
  int _idx = 0;

  T get next {
    if (_idx >= _values.length) {
      _idx = 0;
    }
    return _values[_idx++];
  }
}

extension FlexiPathDraw on Canvas {
  /// 绘制虚线
  void drawDashPath(
    Path path,
    Paint paint, {
    List<double>? dashes,
  }) {
    drawPath(
      dashPath(
        path,
        dashArray: CircularIntervalList<double>(
          dashes ?? <double>[5, 3],
        ),
      ),
      paint,
    );
  }

  /// 绘制线(根据LineType)
  /// 推荐使用drawLineByConfig
  void drawLineType(
    LineType type,
    Path path,
    Paint paint, {
    List<double>? dashes,
  }) {
    if (type == LineType.dashed) {
      drawDashPath(path, paint, dashes: dashes);
    } else if (type == LineType.dotted) {
      // final paint = Paint.from(paint);
      paint.strokeJoin = StrokeJoin.round;
      paint.strokeCap = StrokeCap.round;
      paint.isAntiAlias = true;
      final width = paint.strokeWidth;
      drawDashPath(path, paint, dashes: [1, width * 2]);
    } else {
      drawPath(path, paint);
    }
  }

  /// 绘制线(根据LineConfig)
  void drawLineByConfig(
    Path path,
    LineConfig config,
  ) =>
      drawLineType(
        config.type,
        path,
        config.linePaint,
        dashes: config.dashes,
      );
}
