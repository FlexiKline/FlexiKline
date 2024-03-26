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
