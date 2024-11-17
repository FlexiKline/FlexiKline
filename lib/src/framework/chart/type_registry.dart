// Copyright 2024 Andy.Zhao
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

part of 'indicator.dart';

class _TypeRegistry {
  final Map<String, _TypeHandler<Indicator>> _registry = {};
  final Map<Type, _TypeHandler<Indicator>> _reverseRegistry = {};

  void register<T extends Indicator>(
    String typeId,
    T? Function(dynamic json) fromJson,
  ) {
    if (T == dynamic) {
      throw ArgumentError('Cannot register dynamic type.');
    }

    final handler = _TypeHandler<T>(typeId, fromJson);
    _registry[typeId] = handler;
    _reverseRegistry[T] = handler;
  }

  T fromJson<T extends Indicator>(
    String? typeId,
    dynamic json,
  ) {
    dynamic value = json;
    if (typeId != null) {
      final handler = _registry[typeId];
      if (handler == null) {
        throw StateError(
          'Type is not registered. Did you forget to register it?',
        );
      }
      if (json is Map<String, dynamic>) {
        value = handler.fromJson(json);
      } else {
        throw ArgumentError(
          'Type mismatch. Expected Map<String,dynamic> '
          'but got ${json.runtimeType}.',
        );
      }
    }

    if (value is T) {
      return value;
    } else {
      throw ArgumentError(
        'Type mismatch. Expected $T but got ${value.runtimeType}.',
      );
    }
  }

  String? findTypeId<T extends Indicator>(T value) {
    final handler = _reverseRegistry[value.runtimeType];
    if (handler != null) {
      return handler.typeId;
    }

    for (final MapEntry(key: type, value: handler)
        in _reverseRegistry.entries) {
      if (handler.handlesValue(value)) {
        _reverseRegistry[type] = handler;
        return handler.typeId;
      }
    }

    return null;
  }

  void reset() {
    _registry.clear();
    _reverseRegistry.clear();
  }
}

T? _noop<T extends Indicator>(Map<String, dynamic> json) {
  throw UnimplementedError();
}

class _TypeHandler<T extends Indicator> {
  const _TypeHandler(this.typeId, this.fromJson);

  const _TypeHandler.builtin()
      : typeId = null,
        fromJson = _noop;

  final String? typeId;

  final T? Function(Map<String, dynamic> json) fromJson;

  bool handlesValue(dynamic value) {
    return value is T;
  }
}
