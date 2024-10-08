// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a zh locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'zh';

  static String m0(unit) => "24小时额(${unit})";

  static String m1(unit) => "24小时量(${unit})";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "about": MessageLookupByLibrary.simpleMessage("关于"),
        "badCertificate": MessageLookupByLibrary.simpleMessage("证书错误"),
        "bit": MessageLookupByLibrary.simpleMessage("Bit"),
        "canceled": MessageLookupByLibrary.simpleMessage("已取消"),
        "cannotReachServer": MessageLookupByLibrary.simpleMessage("无法连接服务器"),
        "chartHeight": MessageLookupByLibrary.simpleMessage("图表高度"),
        "chartSettings": MessageLookupByLibrary.simpleMessage("图表设置"),
        "chartWidth": MessageLookupByLibrary.simpleMessage("图表宽度"),
        "connectionError": MessageLookupByLibrary.simpleMessage("连接错误"),
        "connectionTimeout": MessageLookupByLibrary.simpleMessage("客户端连接超时"),
        "countdown": MessageLookupByLibrary.simpleMessage("倒计时"),
        "demo": MessageLookupByLibrary.simpleMessage("示例"),
        "drawings": MessageLookupByLibrary.simpleMessage("画图"),
        "h24_high": MessageLookupByLibrary.simpleMessage("24小时最高"),
        "h24_low": MessageLookupByLibrary.simpleMessage("24小时最低"),
        "h24_turnover": m0,
        "h24_vol": m1,
        "highPrice": MessageLookupByLibrary.simpleMessage("最高价"),
        "indicatorSetting": MessageLookupByLibrary.simpleMessage("指标设置"),
        "indicators": MessageLookupByLibrary.simpleMessage("指标"),
        "intervals": MessageLookupByLibrary.simpleMessage("全部周期"),
        "invalidReq": MessageLookupByLibrary.simpleMessage("无效的请求"),
        "label24HChange": MessageLookupByLibrary.simpleMessage("24H涨跌幅"),
        "labelNameVol": MessageLookupByLibrary.simpleMessage("名称/成交量"),
        "labelPrice": MessageLookupByLibrary.simpleMessage("最新价"),
        "landscape": MessageLookupByLibrary.simpleMessage("横屏"),
        "lastPrice": MessageLookupByLibrary.simpleMessage("最新价"),
        "loadFailed": MessageLookupByLibrary.simpleMessage("加载失败!"),
        "lowPrice": MessageLookupByLibrary.simpleMessage("最低价"),
        "mainChartIndicators": MessageLookupByLibrary.simpleMessage("主图指标"),
        "more": MessageLookupByLibrary.simpleMessage("更多"),
        "ok": MessageLookupByLibrary.simpleMessage("Ok"),
        "permissionDenied": MessageLookupByLibrary.simpleMessage("没有权限"),
        "preferredIntervals": MessageLookupByLibrary.simpleMessage("周期偏好"),
        "reqMethodForbidden": MessageLookupByLibrary.simpleMessage("请求方法被禁止"),
        "responseTimeout": MessageLookupByLibrary.simpleMessage("服务端响应超时"),
        "searchTradingPairHint": MessageLookupByLibrary.simpleMessage("请输入交易对"),
        "selectTradingPair": MessageLookupByLibrary.simpleMessage("币种选择"),
        "sendTimeout": MessageLookupByLibrary.simpleMessage("客户端发送超时"),
        "serverDown": MessageLookupByLibrary.simpleMessage("服务器挂了"),
        "serverInternalError": MessageLookupByLibrary.simpleMessage("服务器内部错误"),
        "serverRefused": MessageLookupByLibrary.simpleMessage("服务器拒绝执行"),
        "setting": MessageLookupByLibrary.simpleMessage("设置"),
        "settingLanguage": MessageLookupByLibrary.simpleMessage("语言"),
        "settingThemeMode": MessageLookupByLibrary.simpleMessage("主题模式"),
        "subChartIndicators": MessageLookupByLibrary.simpleMessage("副图指标"),
        "syntaxError": MessageLookupByLibrary.simpleMessage("请求语法错误"),
        "themeModeDark": MessageLookupByLibrary.simpleMessage("夜间模式"),
        "themeModeLight": MessageLookupByLibrary.simpleMessage("日间模式"),
        "themeModeSystem": MessageLookupByLibrary.simpleMessage("跟随系统"),
        "title": MessageLookupByLibrary.simpleMessage("FlexiKline"),
        "tooltipAmount": MessageLookupByLibrary.simpleMessage("成交量"),
        "tooltipChg": MessageLookupByLibrary.simpleMessage("涨跌额"),
        "tooltipChgRate": MessageLookupByLibrary.simpleMessage("涨跌幅"),
        "tooltipClose": MessageLookupByLibrary.simpleMessage("收盘"),
        "tooltipHigh": MessageLookupByLibrary.simpleMessage("最高"),
        "tooltipLow": MessageLookupByLibrary.simpleMessage("最低"),
        "tooltipOpen": MessageLookupByLibrary.simpleMessage("开盘"),
        "tooltipRange": MessageLookupByLibrary.simpleMessage("振幅"),
        "tooltipTime": MessageLookupByLibrary.simpleMessage("时间"),
        "tooltipTurnover": MessageLookupByLibrary.simpleMessage("成交额"),
        "unknownError": MessageLookupByLibrary.simpleMessage("未知错误"),
        "unsupportedProtocol":
            MessageLookupByLibrary.simpleMessage("不支持HTTP协议请求"),
        "yAxisPriceScale": MessageLookupByLibrary.simpleMessage("Y轴坐标")
      };
}
