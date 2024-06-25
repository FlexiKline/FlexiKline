// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'line_config.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LineConfigCWProxy {
  LineConfig type(LineType type);

  LineConfig color(Color color);

  LineConfig length(double? length);

  LineConfig width(double width);

  LineConfig dashes(List<double> dashes);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `LineConfig(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// LineConfig(...).copyWith(id: 12, name: "My name")
  /// ````
  LineConfig call({
    LineType? type,
    Color? color,
    double? length,
    double? width,
    List<double>? dashes,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfLineConfig.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfLineConfig.copyWith.fieldName(...)`
class _$LineConfigCWProxyImpl implements _$LineConfigCWProxy {
  const _$LineConfigCWProxyImpl(this._value);

  final LineConfig _value;

  @override
  LineConfig type(LineType type) => this(type: type);

  @override
  LineConfig color(Color color) => this(color: color);

  @override
  LineConfig length(double? length) => this(length: length);

  @override
  LineConfig width(double width) => this(width: width);

  @override
  LineConfig dashes(List<double> dashes) => this(dashes: dashes);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `LineConfig(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// LineConfig(...).copyWith(id: 12, name: "My name")
  /// ````
  LineConfig call({
    Object? type = const $CopyWithPlaceholder(),
    Object? color = const $CopyWithPlaceholder(),
    Object? length = const $CopyWithPlaceholder(),
    Object? width = const $CopyWithPlaceholder(),
    Object? dashes = const $CopyWithPlaceholder(),
  }) {
    return LineConfig(
      type: type == const $CopyWithPlaceholder() || type == null
          ? _value.type
          // ignore: cast_nullable_to_non_nullable
          : type as LineType,
      color: color == const $CopyWithPlaceholder() || color == null
          ? _value.color
          // ignore: cast_nullable_to_non_nullable
          : color as Color,
      length: length == const $CopyWithPlaceholder()
          ? _value.length
          // ignore: cast_nullable_to_non_nullable
          : length as double?,
      width: width == const $CopyWithPlaceholder() || width == null
          ? _value.width
          // ignore: cast_nullable_to_non_nullable
          : width as double,
      dashes: dashes == const $CopyWithPlaceholder() || dashes == null
          ? _value.dashes
          // ignore: cast_nullable_to_non_nullable
          : dashes as List<double>,
    );
  }
}

extension $LineConfigCopyWith on LineConfig {
  /// Returns a callable class that can be used as follows: `instanceOfLineConfig.copyWith(...)` or like so:`instanceOfLineConfig.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LineConfigCWProxy get copyWith => _$LineConfigCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LineConfig _$LineConfigFromJson(Map<String, dynamic> json) => LineConfig(
      type: json['type'] == null
          ? LineType.solid
          : const LineTypeConverter().fromJson(json['type'] as String),
      color: json['color'] == null
          ? Colors.black
          : const ColorConverter().fromJson(json['color'] as String),
      length: (json['length'] as num?)?.toDouble(),
      width: (json['width'] as num?)?.toDouble() ?? 0.5,
      dashes: (json['dashes'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          const [3, 3],
    );

Map<String, dynamic> _$LineConfigToJson(LineConfig instance) {
  final val = <String, dynamic>{
    'type': const LineTypeConverter().toJson(instance.type),
    'color': const ColorConverter().toJson(instance.color),
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('length', instance.length);
  val['width'] = instance.width;
  val['dashes'] = instance.dashes;
  return val;
}
