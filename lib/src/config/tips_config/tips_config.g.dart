// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tips_config.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TipsConfigCWProxy {
  TipsConfig label(String label);

  TipsConfig precision(int? precision);

  TipsConfig style(TextStyle style);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TipsConfig(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TipsConfig(...).copyWith(id: 12, name: "My name")
  /// ````
  TipsConfig call({
    String? label,
    int? precision,
    TextStyle? style,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTipsConfig.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTipsConfig.copyWith.fieldName(...)`
class _$TipsConfigCWProxyImpl implements _$TipsConfigCWProxy {
  const _$TipsConfigCWProxyImpl(this._value);

  final TipsConfig _value;

  @override
  TipsConfig label(String label) => this(label: label);

  @override
  TipsConfig precision(int? precision) => this(precision: precision);

  @override
  TipsConfig style(TextStyle style) => this(style: style);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TipsConfig(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TipsConfig(...).copyWith(id: 12, name: "My name")
  /// ````
  TipsConfig call({
    Object? label = const $CopyWithPlaceholder(),
    Object? precision = const $CopyWithPlaceholder(),
    Object? style = const $CopyWithPlaceholder(),
  }) {
    return TipsConfig(
      label: label == const $CopyWithPlaceholder() || label == null
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String,
      precision: precision == const $CopyWithPlaceholder()
          ? _value.precision
          // ignore: cast_nullable_to_non_nullable
          : precision as int?,
      style: style == const $CopyWithPlaceholder() || style == null
          ? _value.style
          // ignore: cast_nullable_to_non_nullable
          : style as TextStyle,
    );
  }
}

extension $TipsConfigCopyWith on TipsConfig {
  /// Returns a callable class that can be used as follows: `instanceOfTipsConfig.copyWith(...)` or like so:`instanceOfTipsConfig.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TipsConfigCWProxy get copyWith => _$TipsConfigCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TipsConfig _$TipsConfigFromJson(Map<String, dynamic> json) => TipsConfig(
      label: json['label'] as String? ?? '',
      precision: (json['precision'] as num?)?.toInt(),
      style: json['style'] == null
          ? const TextStyle(
              fontSize: defaulTextSize,
              color: Colors.black,
              overflow: TextOverflow.ellipsis,
              height: defaultTipsTextHeight)
          : const TextStyleConverter()
              .fromJson(json['style'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TipsConfigToJson(TipsConfig instance) {
  final val = <String, dynamic>{
    'label': instance.label,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('precision', instance.precision);
  val['style'] = const TextStyleConverter().toJson(instance.style);
  return val;
}
