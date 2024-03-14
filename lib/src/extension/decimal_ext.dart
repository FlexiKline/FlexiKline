import 'package:decimal/decimal.dart';

extension StringExt on String {
  Decimal? get decimal => Decimal.tryParse(this);
  Decimal get d => Decimal.tryParse(this) ?? Decimal.zero;
}

extension DoubleExt on double {
  Decimal? get decimal => Decimal.tryParse(toString());
  Decimal get d => Decimal.tryParse(toString()) ?? Decimal.zero;
}

extension IntExt on int {
  Decimal? get decimal => Decimal.tryParse(toString());
  Decimal get d => Decimal.tryParse(toString()) ?? Decimal.zero;
}
