import 'package:decimal/decimal.dart';
import '../extension/export.dart';

String formatPercentage(double val, {int precision = 2}) {
  return '${val.toStringAsPrecision(precision)}%';
}

String formatBigDecimal(Decimal val) {
  if (val.abs() >= 1e9.d) {
    return '${(val / 1e9.d).toDecimal().toStringAsFixed(2)}B';
  } else if (val.abs() >= 1e6.d) {
    return '${(val / 1e6.d).toDecimal().toStringAsFixed(2)}M';
  } else if (val.abs() >= 1e3.d) {
    return '${(val / 1e3.d).toDecimal().toStringAsFixed(2)}K';
  } else {
    return val.toStringAsFixed(2);
  }
}

String twoDigits(int n) {
  if (n >= 10) return "$n";
  return "0$n";
}
