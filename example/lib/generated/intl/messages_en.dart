// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
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
  String get localeName => 'en';

  static String m0(unit) => "24h turnover(${unit})";

  static String m1(unit) => "24h vol(${unit})";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "about": MessageLookupByLibrary.simpleMessage("About"),
        "appExitTips": MessageLookupByLibrary.simpleMessage(
            "Press again to close the app"),
        "badCertificate":
            MessageLookupByLibrary.simpleMessage("Bad certificate"),
        "bit": MessageLookupByLibrary.simpleMessage("Bit"),
        "canceled": MessageLookupByLibrary.simpleMessage("Canceled"),
        "cannotReachServer":
            MessageLookupByLibrary.simpleMessage("Can not reach server"),
        "chartHeight": MessageLookupByLibrary.simpleMessage("Chart Height"),
        "chartSettings": MessageLookupByLibrary.simpleMessage("Chart settings"),
        "chartWidth": MessageLookupByLibrary.simpleMessage("Chart Width"),
        "connectionError":
            MessageLookupByLibrary.simpleMessage("Connection error"),
        "connectionTimeout":
            MessageLookupByLibrary.simpleMessage("Client connection timeout"),
        "countdown": MessageLookupByLibrary.simpleMessage("Countdown"),
        "demo": MessageLookupByLibrary.simpleMessage("Demo"),
        "drawings": MessageLookupByLibrary.simpleMessage("Drawings"),
        "h24_high": MessageLookupByLibrary.simpleMessage("24h high"),
        "h24_low": MessageLookupByLibrary.simpleMessage("24h low"),
        "h24_turnover": m0,
        "h24_vol": m1,
        "highPrice": MessageLookupByLibrary.simpleMessage("High Price"),
        "indicatorSetting":
            MessageLookupByLibrary.simpleMessage("Indicator settings"),
        "indicators": MessageLookupByLibrary.simpleMessage("Indicators"),
        "intervals": MessageLookupByLibrary.simpleMessage("Intervals"),
        "invalidReq": MessageLookupByLibrary.simpleMessage("Invalid request"),
        "label24HChange": MessageLookupByLibrary.simpleMessage("24H Change"),
        "labelNameVol": MessageLookupByLibrary.simpleMessage("Name/Vol"),
        "labelPrice": MessageLookupByLibrary.simpleMessage("Price"),
        "landscape": MessageLookupByLibrary.simpleMessage("Landscape"),
        "lastPrice": MessageLookupByLibrary.simpleMessage("Last price"),
        "loadFailed": MessageLookupByLibrary.simpleMessage("Load failed!"),
        "lowPrice": MessageLookupByLibrary.simpleMessage("Low Price"),
        "mainChartIndicators":
            MessageLookupByLibrary.simpleMessage("Main-chart indicators"),
        "more": MessageLookupByLibrary.simpleMessage("More"),
        "ok": MessageLookupByLibrary.simpleMessage("Ok"),
        "permissionDenied":
            MessageLookupByLibrary.simpleMessage("Permission denied"),
        "preferredIntervals":
            MessageLookupByLibrary.simpleMessage("Preferred intervals"),
        "reqMethodForbidden":
            MessageLookupByLibrary.simpleMessage("Request method is forbidden"),
        "responseTimeout":
            MessageLookupByLibrary.simpleMessage("Server response timeout"),
        "searchTradingPairHint": MessageLookupByLibrary.simpleMessage(
            "Please enter preferred trading pair"),
        "selectTradingPair":
            MessageLookupByLibrary.simpleMessage("Select Trading Pair"),
        "sendTimeout":
            MessageLookupByLibrary.simpleMessage("Client send timeout"),
        "serverDown":
            MessageLookupByLibrary.simpleMessage("The server is down"),
        "serverInternalError":
            MessageLookupByLibrary.simpleMessage("Server internal error"),
        "serverRefused":
            MessageLookupByLibrary.simpleMessage("Server refuses to execute"),
        "setting": MessageLookupByLibrary.simpleMessage("Setting"),
        "settingLanguage": MessageLookupByLibrary.simpleMessage("Language"),
        "settingThemeMode": MessageLookupByLibrary.simpleMessage("Theme Mode"),
        "subChartIndicators":
            MessageLookupByLibrary.simpleMessage("Sub-chart indicators"),
        "syntaxError":
            MessageLookupByLibrary.simpleMessage("Request syntax error"),
        "themeModeDark": MessageLookupByLibrary.simpleMessage("Dark"),
        "themeModeLight": MessageLookupByLibrary.simpleMessage("Light"),
        "themeModeSystem": MessageLookupByLibrary.simpleMessage("System"),
        "title": MessageLookupByLibrary.simpleMessage("FlexiKline"),
        "tooltipAmount": MessageLookupByLibrary.simpleMessage("Amount"),
        "tooltipChg": MessageLookupByLibrary.simpleMessage("Chg"),
        "tooltipChgRate": MessageLookupByLibrary.simpleMessage("%Chg"),
        "tooltipClose": MessageLookupByLibrary.simpleMessage("Close"),
        "tooltipHigh": MessageLookupByLibrary.simpleMessage("High"),
        "tooltipLow": MessageLookupByLibrary.simpleMessage("Low"),
        "tooltipOpen": MessageLookupByLibrary.simpleMessage("Open"),
        "tooltipRange": MessageLookupByLibrary.simpleMessage("Range"),
        "tooltipTime": MessageLookupByLibrary.simpleMessage("Time"),
        "tooltipTurnover": MessageLookupByLibrary.simpleMessage("Turnover"),
        "unknownError": MessageLookupByLibrary.simpleMessage("Unknown error"),
        "unsupportedProtocol": MessageLookupByLibrary.simpleMessage(
            "HTTP protocol requests are not supported"),
        "yAxisPriceScale":
            MessageLookupByLibrary.simpleMessage("Price scale(y-axis)")
      };
}
