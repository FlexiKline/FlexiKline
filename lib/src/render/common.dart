enum DrawDirection {
  /// The draw flows from left to right.
  ltr,

  center,

  /// The draw flows from right to left.
  rtl;

  bool get isltr => this == ltr;
  bool get isCenter => this == center;
  bool get isrtl => this == rtl;
}
