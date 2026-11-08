import 'package:get_it/get_it.dart';

/// 依赖容器；展示层只依赖本文件取实例，注册在 `repository_registry.dart`，由 `main.dart` 调用。
final getIt = GetIt.instance;
