import 'dart:math' as math;

/// 计算时间差, 并格式化展示
/// 1. 超过1天展示 "md nh"
/// 2. 小于一天展示 "hh:MM:ss"
/// 3. 小天一小时展示 "MM:ss"
String? calculateTimeDiff(DateTime nextUpdateDateTime) {
  final timeLag = nextUpdateDateTime.difference(DateTime.now());
  if (timeLag.isNegative) {
    // debugPrint(
    //   'calculateTimeDiff > next:$nextUpdateDateTime - now:${DateTime.now()} = $timeLag',
    // );
    return null;
  }

  final dayLag = timeLag.inDays;
  if (dayLag >= 1) {
    final hoursLag = (timeLag.inHours - dayLag * 24).clamp(0, 23);
    return '${dayLag}h ${hoursLag}h';
  } else {
    return timeLag.toString().substring(0, 8);
  }
}

/// 格式化日期时间.
/// 如果与今天时间一致不展示(年月日) 和 (月日)
/// lg:
/// DateTime date = DateTime(2024, 3, 27, 19, 50, 32);
/// print(formatyyMMddHHMMss(date)); // 19:50:32
/// date = DateTime(2024, 2, 26, 19, 50, 32);
/// print(formatyyMMddHHMMss(date)); // 02/26 19:50:32
/// date = DateTime(2022, 2, 26, 19, 50, 32);
/// print(formatyyMMddHHMMss(date)); // 22/02/26 19:50:32
///
String formatyyMMddHHMMss(
  DateTime dateTime, {
  bool omitYear = true, // 当日期是今年时,是否省略.
}) {
  String fillzero(int n) {
    if (n >= 10) return "$n";
    return "0$n";
  }

  final now = DateTime.now();
  int year = dateTime.year;
  StringBuffer sb = StringBuffer();
  if (now.difference(dateTime).inDays > 1) {
    // dateTime 与当前时间相差大于一天. 展示年月日
    if (!omitYear || year != now.year) {
      final str = year.toString();
      sb.write(str.substring(math.max(0, str.length - 2)));
      sb.write('/');
    }
    sb.write(fillzero(dateTime.month));
    sb.write('/');
    sb.write(fillzero(dateTime.day));
    sb.write(' ');
  }

  sb.write(fillzero(dateTime.hour));
  sb.write(':');
  sb.write(fillzero(dateTime.minute));
  sb.write(':');
  sb.write(fillzero(dateTime.second));

  return sb.toString();
}
