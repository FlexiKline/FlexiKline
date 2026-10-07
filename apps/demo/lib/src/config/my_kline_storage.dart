import 'package:flexi_kline/flexi_kline.dart';

/// 进程内存储 mixin：配置仅在内存流转、不落盘。
///
/// 混入即获得 [IStorage] 的默认实现；存储键前缀由 [storageKeyPrefix] 决定，
/// 子类可覆写它或直接覆写 [cacheKey]。
mixin MyKlineStorageMixin implements IStorage {
  final Map<String, Map<String, dynamic>> _store = {};

  /// 存储键前缀，默认 `my_kline_`，子类可覆写。
  String get storageKeyPrefix => 'my_kline_';

  /// 最终存储键，默认 `$storageKeyPrefix$key`。
  String cacheKey(String key) => '$storageKeyPrefix$key';

  @override
  Map<String, dynamic>? getConfig(String key) => _store[cacheKey(key)];

  @override
  Future<bool> setConfig(String key, Map<String, dynamic> value) async {
    _store[cacheKey(key)] = value;
    return true;
  }
}
