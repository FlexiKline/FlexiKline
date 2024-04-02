import 'dart:ui';

extension OffsetExt on Rect {
  /// Whether the point specified by the given offset (which is assumed to be
  /// relative to the origin) lies between the left and right and the top and
  /// bottom edges of this rectangle.
  ///
  /// Rectangles include their top, left, bottom and right edges.
  bool include(Offset offset) {
    return offset.dx >= left &&
        offset.dx <= right &&
        offset.dy >= top &&
        offset.dy <= bottom;
  }

  bool inclueDx(double dx) {
    return dx >= left && dx <= right;
  }

  bool inclueDy(double dy) {
    return dy >= top && dy <= bottom;
  }
}
