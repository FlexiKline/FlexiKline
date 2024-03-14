import 'dart:ui';

/// Creates a new path that is drawn from the segments of `source`.
///
/// Dash intervals are controlled by the `dashArray` - see [CircularIntervalList]
/// for examples.
///
/// `dashOffset` specifies an initial starting point for the dashing.
///
/// Passing in a null `source` will result in a null result.  Passing a `source`
/// that is an empty path will return an empty path.
extension PathExtension on Path {
  Path dashPath({
    required CircularIntervalList<double> dashArray,
    DashOffset? dashOffset,
  }) {
    dashOffset = dashOffset ?? const DashOffset.absolute(0.0);

    final Path dest = Path();
    for (final PathMetric metric in computeMetrics()) {
      double distance = dashOffset._calculate(metric.length);
      bool draw = true;
      while (distance < metric.length) {
        final double len = dashArray.next;
        if (draw) {
          dest.addPath(
            metric.extractPath(distance, distance + len),
            Offset.zero,
          );
        }
        distance += len;
        draw = !draw;
      }
    }
    return dest;
  }
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
  /// `percentage` will be clamped between 0.0 and 1.0; null will be converted
  /// to 0.0.
  DashOffset.percentage(double percentage)
      : _rawVal = (percentage.clamp(0.0, 1.0)).toDouble(),
        _dashOffsetType = _DashOffsetType.percentage;

  /// Create a DashOffset that will be measured in terms of absolute pixels
  /// along the length of a [Path] segment.
  ///
  /// `start` will be coerced to 0.0 if null.
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
  CircularIntervalList(this._valList);

  final List<T> _valList;
  int _idx = 0;

  T get next {
    if (_idx >= _valList.length) {
      _idx = 0;
    }
    return _valList[_idx++];
  }
}

extension PathDraw on Canvas {
  /// 绘制虚线
  void drawDashPath(
    Path path,
    Paint paint, {
    List<double>? dashes,
  }) {
    drawPath(
      path.dashPath(
        dashArray: CircularIntervalList<double>(
          dashes ?? <double>[5, 3],
        ),
      ),
      paint,
    );
  }
}
