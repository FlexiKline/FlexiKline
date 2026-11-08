import 'data_sources/mock/mock_kline_data_source.dart';
import 'repositories/kline_repository.dart';
import 'repositories/kline_repository_impl.dart';
import 'service_locator.dart';

/// 注册数据层单例；接入真实后端时在这里替换 [MockKlineDataSource]。
///
/// 横竖屏页面取到同一个 [KlineRepository]，共用数据源的缓存。
void registerRepositories() {
  getIt.registerLazySingleton<KlineRepository>(() => KlineRepositoryImpl(MockKlineDataSource()));
}
