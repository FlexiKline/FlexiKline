import 'package:decimal/decimal.dart';

Decimal stringToDecimal(dynamic value) =>
    stringToDecimalOrNull(value) ?? Decimal.zero;

Decimal? stringToDecimalOrNull(dynamic value) {
  if (value == null) {
    return null;
  } else {
    return Decimal.tryParse(value.toString());
  }
}

String decimalToString(dynamic value) => value?.toString() ?? "";

String? decimalToStringOrNull(dynamic value) => value?.toString();

DateTime? valueToDateTime(dynamic value) {
  if (value == null) {
    return null;
  } else if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  } else if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}

int? dateTimeToInt(dynamic dateTime) {
  if (dateTime == null) {
    return null;
  } else if (dateTime is DateTime) {
    return dateTime.millisecondsSinceEpoch;
  } else if (dateTime is int) {
    return dateTime;
  }
  return int.tryParse(dateTime.toString());
}
