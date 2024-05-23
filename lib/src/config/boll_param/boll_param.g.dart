// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'boll_param.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BOLLParamCWProxy {
  BOLLParam n(int n);

  BOLLParam std(int std);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `BOLLParam(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// BOLLParam(...).copyWith(id: 12, name: "My name")
  /// ````
  BOLLParam call({
    int? n,
    int? std,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfBOLLParam.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfBOLLParam.copyWith.fieldName(...)`
class _$BOLLParamCWProxyImpl implements _$BOLLParamCWProxy {
  const _$BOLLParamCWProxyImpl(this._value);

  final BOLLParam _value;

  @override
  BOLLParam n(int n) => this(n: n);

  @override
  BOLLParam std(int std) => this(std: std);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `BOLLParam(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// BOLLParam(...).copyWith(id: 12, name: "My name")
  /// ````
  BOLLParam call({
    Object? n = const $CopyWithPlaceholder(),
    Object? std = const $CopyWithPlaceholder(),
  }) {
    return BOLLParam(
      n: n == const $CopyWithPlaceholder() || n == null
          ? _value.n
          // ignore: cast_nullable_to_non_nullable
          : n as int,
      std: std == const $CopyWithPlaceholder() || std == null
          ? _value.std
          // ignore: cast_nullable_to_non_nullable
          : std as int,
    );
  }
}

extension $BOLLParamCopyWith on BOLLParam {
  /// Returns a callable class that can be used as follows: `instanceOfBOLLParam.copyWith(...)` or like so:`instanceOfBOLLParam.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BOLLParamCWProxy get copyWith => _$BOLLParamCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BOLLParam _$BOLLParamFromJson(Map<String, dynamic> json) => BOLLParam(
      n: (json['n'] as num).toInt(),
      std: (json['std'] as num).toInt(),
    );

Map<String, dynamic> _$BOLLParamToJson(BOLLParam instance) => <String, dynamic>{
      'n': instance.n,
      'std': instance.std,
    };
