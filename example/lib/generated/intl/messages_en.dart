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

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "badCertificate":
            MessageLookupByLibrary.simpleMessage("Bad certificate"),
        "canceled": MessageLookupByLibrary.simpleMessage("Canceled"),
        "cannotReachServer":
            MessageLookupByLibrary.simpleMessage("Can not reach server"),
        "connectionError":
            MessageLookupByLibrary.simpleMessage("Connection error"),
        "connectionTimeout":
            MessageLookupByLibrary.simpleMessage("Client connection timeout"),
        "demo": MessageLookupByLibrary.simpleMessage("Demo"),
        "invalidReq": MessageLookupByLibrary.simpleMessage("Invalid request"),
        "ko": MessageLookupByLibrary.simpleMessage("KO"),
        "permissionDenied":
            MessageLookupByLibrary.simpleMessage("Permission denied"),
        "reqMethodForbidden":
            MessageLookupByLibrary.simpleMessage("Request method is forbidden"),
        "responseTimeout":
            MessageLookupByLibrary.simpleMessage("Server response timeout"),
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
        "syntaxError":
            MessageLookupByLibrary.simpleMessage("Request syntax error"),
        "themeModeDark": MessageLookupByLibrary.simpleMessage("Dark"),
        "themeModeLight": MessageLookupByLibrary.simpleMessage("Light"),
        "themeModeSystem": MessageLookupByLibrary.simpleMessage("System"),
        "title": MessageLookupByLibrary.simpleMessage("FlexiKline"),
        "unknownError": MessageLookupByLibrary.simpleMessage("Unknown error"),
        "unsupportedProtocol": MessageLookupByLibrary.simpleMessage(
            "HTTP protocol requests are not supported")
      };
}
