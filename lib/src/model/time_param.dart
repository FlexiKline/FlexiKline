import '../constant.dart';

class TimeParams {
  TimeParams({
    required this.type,
    required this.value,
  }) {
    switch (type) {
      case TimeParamsType.time:
      case TimeParamsType.minute:
        minute = value;
        break;
      case TimeParamsType.hour:
        minute = value * 60;
        break;
      case TimeParamsType.day:
        minute = value * 60 * 24;
        break;
      case TimeParamsType.week:
        minute = value * 60 * 24 * 7;
        break;
      case TimeParamsType.month:
        minute = value * 60 * 24 * 30;
        break;
    }
  }

  final TimeParamsType type;
  final int value;
  late int minute;

  factory TimeParams.init() => TimeParams(type: TimeParamsType.time, value: 1);

  @override
  bool operator ==(dynamic other) =>
      other is TimeParams && other.value == value && other.type == type;

  @override
  int get hashCode => type.hashCode ^ value.hashCode;

  String get resolution {
    switch (type) {
      case TimeParamsType.time:
        return '1';
      case TimeParamsType.minute:
        return '$value';
      case TimeParamsType.hour:
        return '${60 * value}';
      case TimeParamsType.day:
        return 'D';
      case TimeParamsType.week:
        return 'W';
      case TimeParamsType.month:
        return 'M';
      default:
        return '';
    }
  }

  int get pageTimeOffset {
    const int pageNo = 500;
    switch (type) {
      case TimeParamsType.time:
        return 60 * pageNo * 1000;
      case TimeParamsType.minute:
        return 60 * value * pageNo * 1000;
      case TimeParamsType.hour:
        return 60 * 60 * value * pageNo * 1000;
      case TimeParamsType.day:
        return 24 * 60 * 60 * value * pageNo * 1000;
      case TimeParamsType.week:
        return 7 * 24 * 60 * 60 * value * pageNo * 1000;
      case TimeParamsType.month:
        return 31 * 24 * 60 * 60 * value * pageNo * 1000;
      default:
        return 10000;
    }
  }

  DateTime preDate(DateTime date) {
    return dateOffset(date, -1);
  }

  DateTime nextDate(DateTime date) {
    return dateOffset(date, 1);
  }

  DateTime dateOffset(DateTime date, int index) {
    if (index == 0) return date;

    switch (type) {
      case TimeParamsType.time:
        return date.add(Duration(minutes: 1 * index));
      case TimeParamsType.minute:
        return date.add(Duration(minutes: value * index));
      case TimeParamsType.hour:
        return date.add(Duration(hours: value * index));
      case TimeParamsType.day:
        return date.add(Duration(days: value * index));
      case TimeParamsType.week:
        return date.add(Duration(days: value * 7 * index));
      case TimeParamsType.month:
        final int day = date.day;
        int year = date.year;
        int month = date.month;
        final int totalMonth = year * 12 + month + index * value;
        year = totalMonth ~/ 12;
        month = totalMonth % 12;
        if (month == 0) {
          month = 12;
          year -= 1;
        }
        return DateTime(year, month, day, date.hour, date.minute, date.second);
      default:
        return date;
    }
  }

  DateTime roundDate(DateTime date) {
    final DateTime utc = date.toUtc();
    switch (type) {
      case TimeParamsType.time:
      case TimeParamsType.minute:
        return DateTime.utc(utc.year, utc.month, utc.day, utc.hour, utc.minute)
            .add(const Duration(minutes: 1));
      case TimeParamsType.hour:
        return DateTime.utc(utc.year, utc.month, utc.day, utc.hour)
            .add(const Duration(hours: 1));
      case TimeParamsType.day:
      case TimeParamsType.week:
      case TimeParamsType.month:
        return DateTime.utc(utc.year, utc.month, utc.day)
            .add(const Duration(days: 1));
      default:
        return date;
    }
  }

  int indexOffsetBetween(DateTime start, DateTime end) {
    switch (type) {
      case TimeParamsType.time:
        return end.difference(start).inMinutes;
      case TimeParamsType.minute:
        return (end.difference(start).inMinutes / value).round();
      case TimeParamsType.hour:
        return (end.difference(start).inHours / value).round();
      case TimeParamsType.day:
        return (end.difference(start).inDays / value).round();
      case TimeParamsType.week:
        return (end.difference(start).inDays / value / 7).round();
      case TimeParamsType.month:
        return (end.difference(start).inDays / value / 30).round();
      default:
        return 0;
    }
  }

  String timeString(DateTime value) {
    final DateTime date = value.toLocal();
    final String hour = date.hour < 10 ? '0${date.hour}' : '${date.hour}';
    final String minute =
        date.minute < 10 ? '0${date.minute}' : '${date.minute}';

    switch (type) {
      case TimeParamsType.time:
      case TimeParamsType.minute:
      case TimeParamsType.hour:
        return '${date.year}-${date.month}-${date.day} $hour:$minute';
      case TimeParamsType.day:
      case TimeParamsType.week:
      case TimeParamsType.month:
        return '${date.year}-${date.month}-${date.day}';
      default:
        return '${date.year}-${date.month}-${date.day} $hour:$minute';
    }
  }

  @override
  String toString() {
    switch (type) {
      case TimeParamsType.time:
        return 'Time';
      case TimeParamsType.minute:
        return '${value}m';
      case TimeParamsType.hour:
        return '${value}H';
      case TimeParamsType.day:
        return '${value}D';
      case TimeParamsType.week:
        return '${value}W';
      case TimeParamsType.month:
        return '${value}M';
      default:
    }
    return '';
  }
}
