import 'package:flexi_kline/flexi_kline.dart';

/// 内存版 [IStorage]，配置仅在进程内流转、无需落盘。
abstract class MyKlineStorage implements IStorage {
  final Map<String, Map<String, dynamic>> _store = {};

  /// 存储键前缀，由具体配置子类覆写。
  String cacheKey(String key);

  @override
  Map<String, dynamic>? getConfig(String key) => _store[cacheKey(key)];

  @override
  Future<bool> setConfig(String key, Map<String, dynamic> value) async {
    _store[cacheKey(key)] = value;
    return true;
  }
}
