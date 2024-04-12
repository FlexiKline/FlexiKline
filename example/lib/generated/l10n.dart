// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(_current != null,
        'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.');
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(instance != null,
        'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?');
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `FlexiKline`
  String get title {
    return Intl.message(
      'FlexiKline',
      name: 'title',
      desc: '',
      args: [],
    );
  }

  /// `Demo`
  String get demo {
    return Intl.message(
      'Demo',
      name: 'demo',
      desc: '',
      args: [],
    );
  }

  /// `KO`
  String get ko {
    return Intl.message(
      'KO',
      name: 'ko',
      desc: '',
      args: [],
    );
  }

  /// `Client connection timeout`
  String get connectionTimeout {
    return Intl.message(
      'Client connection timeout',
      name: 'connectionTimeout',
      desc: '',
      args: [],
    );
  }

  /// `Client send timeout`
  String get sendTimeout {
    return Intl.message(
      'Client send timeout',
      name: 'sendTimeout',
      desc: '',
      args: [],
    );
  }

  /// `Server response timeout`
  String get responseTimeout {
    return Intl.message(
      'Server response timeout',
      name: 'responseTimeout',
      desc: '',
      args: [],
    );
  }

  /// `Canceled`
  String get canceled {
    return Intl.message(
      'Canceled',
      name: 'canceled',
      desc: '',
      args: [],
    );
  }

  /// `Request syntax error`
  String get syntaxError {
    return Intl.message(
      'Request syntax error',
      name: 'syntaxError',
      desc: '',
      args: [],
    );
  }

  /// `Permission denied`
  String get permissionDenied {
    return Intl.message(
      'Permission denied',
      name: 'permissionDenied',
      desc: '',
      args: [],
    );
  }

  /// `Server refuses to execute`
  String get serverRefused {
    return Intl.message(
      'Server refuses to execute',
      name: 'serverRefused',
      desc: '',
      args: [],
    );
  }

  /// `Can not reach server`
  String get cannotReachServer {
    return Intl.message(
      'Can not reach server',
      name: 'cannotReachServer',
      desc: '',
      args: [],
    );
  }

  /// `Request method is forbidden`
  String get reqMethodForbidden {
    return Intl.message(
      'Request method is forbidden',
      name: 'reqMethodForbidden',
      desc: '',
      args: [],
    );
  }

  /// `Server internal error`
  String get serverInternalError {
    return Intl.message(
      'Server internal error',
      name: 'serverInternalError',
      desc: '',
      args: [],
    );
  }

  /// `Invalid request`
  String get invalidReq {
    return Intl.message(
      'Invalid request',
      name: 'invalidReq',
      desc: '',
      args: [],
    );
  }

  /// `The server is down`
  String get serverDown {
    return Intl.message(
      'The server is down',
      name: 'serverDown',
      desc: '',
      args: [],
    );
  }

  /// `HTTP protocol requests are not supported`
  String get unsupportedProtocol {
    return Intl.message(
      'HTTP protocol requests are not supported',
      name: 'unsupportedProtocol',
      desc: '',
      args: [],
    );
  }

  /// `Bad certificate`
  String get badCertificate {
    return Intl.message(
      'Bad certificate',
      name: 'badCertificate',
      desc: '',
      args: [],
    );
  }

  /// `Connection error`
  String get connectionError {
    return Intl.message(
      'Connection error',
      name: 'connectionError',
      desc: '',
      args: [],
    );
  }

  /// `Unknown error`
  String get unknownError {
    return Intl.message(
      'Unknown error',
      name: 'unknownError',
      desc: '',
      args: [],
    );
  }

  /// `Setting`
  String get setting {
    return Intl.message(
      'Setting',
      name: 'setting',
      desc: '',
      args: [],
    );
  }

  /// `Language`
  String get settingLanguage {
    return Intl.message(
      'Language',
      name: 'settingLanguage',
      desc: '',
      args: [],
    );
  }

  /// `Theme Mode`
  String get settingThemeMode {
    return Intl.message(
      'Theme Mode',
      name: 'settingThemeMode',
      desc: '',
      args: [],
    );
  }

  /// `System`
  String get themeModeSystem {
    return Intl.message(
      'System',
      name: 'themeModeSystem',
      desc: '',
      args: [],
    );
  }

  /// `Light`
  String get themeModeLight {
    return Intl.message(
      'Light',
      name: 'themeModeLight',
      desc: '',
      args: [],
    );
  }

  /// `Dark`
  String get themeModeDark {
    return Intl.message(
      'Dark',
      name: 'themeModeDark',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'zh'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
