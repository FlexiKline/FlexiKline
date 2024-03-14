import 'package:decimal/decimal.dart';

export 'decimal_ext.dart';

Decimal valueToDecimal(dynamic value) {
  if (value == null) {
    return Decimal.zero;
  } else {
    return Decimal.tryParse(value) ?? Decimal.zero;
  }
}

String valueToString(dynamic value) {
  if (value == null) {
    return "";
  }
  return value.toString();
}

final DateTime _emptyDateTime = DateTime.fromMillisecondsSinceEpoch(0);
DateTime valueToDateTime(dynamic value) {
  if (value == null) {
    return _emptyDateTime;
  } else if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  } else if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value) ?? _emptyDateTime;
  }
  return _emptyDateTime;
}

int dateTimeToInt(dynamic dateTime) {
  if (dateTime == null) {
    return 0;
  } else if (dateTime is DateTime) {
    return dateTime.millisecondsSinceEpoch;
  } else if (dateTime is int) {
    return dateTime;
  }
  return int.tryParse(dateTime.toString()) ?? 0;
}
