enum DrawDirection {
  /// The draw flows from left to right.
  ltr,

  /// The draw flows from right to left.
  rtl;

  bool get isltr => this == ltr;
}
