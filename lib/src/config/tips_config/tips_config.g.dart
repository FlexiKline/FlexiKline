// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tips_config.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TipsConfigCWProxy {
  TipsConfig label(String label);

  TipsConfig precision(int? precision);

  TipsConfig isShow(bool isShow);

  TipsConfig style(TextStyle style);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TipsConfig(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TipsConfig(...).copyWith(id: 12, name: "My name")
  /// ````
  TipsConfig call({
    String label,
    int? precision,
    bool isShow,
    TextStyle style,
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
  TipsConfig isShow(bool isShow) => this(isShow: isShow);

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
    Object? isShow = const $CopyWithPlaceholder(),
    Object? style = const $CopyWithPlaceholder(),
  }) {
    return TipsConfig(
      label: label == const $CopyWithPlaceholder()
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String,
      precision: precision == const $CopyWithPlaceholder()
          ? _value.precision
          // ignore: cast_nullable_to_non_nullable
          : precision as int?,
      isShow: isShow == const $CopyWithPlaceholder()
          ? _value.isShow
          // ignore: cast_nullable_to_non_nullable
          : isShow as bool,
      style: style == const $CopyWithPlaceholder()
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
      isShow: json['isShow'] as bool? ?? true,
      style: json['style'] == null
          ? const TextStyle(
              fontSize: defaulTextSize,
              color: Color(0xFF000000),
              overflow: TextOverflow.ellipsis,
              height: defaultTipsTextHeight)
          : const TextStyleConverter()
              .fromJson(json['style'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TipsConfigToJson(TipsConfig instance) =>
    <String, dynamic>{
      'label': instance.label,
      if (instance.precision case final value?) 'precision': value,
      'isShow': instance.isShow,
      'style': const TextStyleConverter().toJson(instance.style),
    };
