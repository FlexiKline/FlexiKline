// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sar_param.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SARParamCWProxy {
  SARParam startAf(double startAf);

  SARParam step(double step);

  SARParam maxAf(double maxAf);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SARParam(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SARParam(...).copyWith(id: 12, name: "My name")
  /// ````
  SARParam call({
    double? startAf,
    double? step,
    double? maxAf,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSARParam.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSARParam.copyWith.fieldName(...)`
class _$SARParamCWProxyImpl implements _$SARParamCWProxy {
  const _$SARParamCWProxyImpl(this._value);

  final SARParam _value;

  @override
  SARParam startAf(double startAf) => this(startAf: startAf);

  @override
  SARParam step(double step) => this(step: step);

  @override
  SARParam maxAf(double maxAf) => this(maxAf: maxAf);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SARParam(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SARParam(...).copyWith(id: 12, name: "My name")
  /// ````
  SARParam call({
    Object? startAf = const $CopyWithPlaceholder(),
    Object? step = const $CopyWithPlaceholder(),
    Object? maxAf = const $CopyWithPlaceholder(),
  }) {
    return SARParam(
      startAf: startAf == const $CopyWithPlaceholder() || startAf == null
          ? _value.startAf
          // ignore: cast_nullable_to_non_nullable
          : startAf as double,
      step: step == const $CopyWithPlaceholder() || step == null
          ? _value.step
          // ignore: cast_nullable_to_non_nullable
          : step as double,
      maxAf: maxAf == const $CopyWithPlaceholder() || maxAf == null
          ? _value.maxAf
          // ignore: cast_nullable_to_non_nullable
          : maxAf as double,
    );
  }
}

extension $SARParamCopyWith on SARParam {
  /// Returns a callable class that can be used as follows: `instanceOfSARParam.copyWith(...)` or like so:`instanceOfSARParam.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SARParamCWProxy get copyWith => _$SARParamCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SARParam _$SARParamFromJson(Map<String, dynamic> json) => SARParam(
      startAf: (json['startAf'] as num?)?.toDouble() ?? 0.02,
      step: (json['step'] as num?)?.toDouble() ?? 0.02,
      maxAf: (json['maxAf'] as num?)?.toDouble() ?? 0.2,
    );

Map<String, dynamic> _$SARParamToJson(SARParam instance) => <String, dynamic>{
      'startAf': instance.startAf,
      'step': instance.step,
      'maxAf': instance.maxAf,
    };
