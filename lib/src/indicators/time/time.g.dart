// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'time.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TimeIndicatorCWProxy {
  TimeIndicator zIndex(int zIndex);

  TimeIndicator height(double height);

  TimeIndicator padding(EdgeInsets padding);

  TimeIndicator position(DrawPosition position);

  TimeIndicator timeLabel(TextAreaConfig timeLabel);

  TimeIndicator clipToDrawableRect(bool clipToDrawableRect);

  TimeIndicator tickFormatter(
      String Function(DateTime, [ITimeInterval?])? tickFormatter);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TimeIndicator(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TimeIndicator(...).copyWith(id: 12, name: "My name")
  /// ````
  TimeIndicator call({
    int zIndex,
    double height,
    EdgeInsets padding,
    DrawPosition position,
    TextAreaConfig timeLabel,
    bool clipToDrawableRect,
    String Function(DateTime, [ITimeInterval?])? tickFormatter,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTimeIndicator.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTimeIndicator.copyWith.fieldName(...)`
class _$TimeIndicatorCWProxyImpl implements _$TimeIndicatorCWProxy {
  const _$TimeIndicatorCWProxyImpl(this._value);

  final TimeIndicator _value;

  @override
  TimeIndicator zIndex(int zIndex) => this(zIndex: zIndex);

  @override
  TimeIndicator height(double height) => this(height: height);

  @override
  TimeIndicator padding(EdgeInsets padding) => this(padding: padding);

  @override
  TimeIndicator position(DrawPosition position) => this(position: position);

  @override
  TimeIndicator timeLabel(TextAreaConfig timeLabel) =>
      this(timeLabel: timeLabel);

  @override
  TimeIndicator clipToDrawableRect(bool clipToDrawableRect) =>
      this(clipToDrawableRect: clipToDrawableRect);

  @override
  TimeIndicator tickFormatter(
          String Function(DateTime, [ITimeInterval?])? tickFormatter) =>
      this(tickFormatter: tickFormatter);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TimeIndicator(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TimeIndicator(...).copyWith(id: 12, name: "My name")
  /// ````
  TimeIndicator call({
    Object? zIndex = const $CopyWithPlaceholder(),
    Object? height = const $CopyWithPlaceholder(),
    Object? padding = const $CopyWithPlaceholder(),
    Object? position = const $CopyWithPlaceholder(),
    Object? timeLabel = const $CopyWithPlaceholder(),
    Object? clipToDrawableRect = const $CopyWithPlaceholder(),
    Object? tickFormatter = const $CopyWithPlaceholder(),
  }) {
    return TimeIndicator(
      zIndex: zIndex == const $CopyWithPlaceholder()
          ? _value.zIndex
          // ignore: cast_nullable_to_non_nullable
          : zIndex as int,
      height: height == const $CopyWithPlaceholder()
          ? _value.height
          // ignore: cast_nullable_to_non_nullable
          : height as double,
      padding: padding == const $CopyWithPlaceholder()
          ? _value.padding
          // ignore: cast_nullable_to_non_nullable
          : padding as EdgeInsets,
      position: position == const $CopyWithPlaceholder()
          ? _value.position
          // ignore: cast_nullable_to_non_nullable
          : position as DrawPosition,
      timeLabel: timeLabel == const $CopyWithPlaceholder()
          ? _value.timeLabel
          // ignore: cast_nullable_to_non_nullable
          : timeLabel as TextAreaConfig,
      clipToDrawableRect: clipToDrawableRect == const $CopyWithPlaceholder()
          ? _value.clipToDrawableRect
          // ignore: cast_nullable_to_non_nullable
          : clipToDrawableRect as bool,
      tickFormatter: tickFormatter == const $CopyWithPlaceholder()
          ? _value.tickFormatter
          // ignore: cast_nullable_to_non_nullable
          : tickFormatter as String Function(DateTime, [ITimeInterval?])?,
    );
  }
}

extension $TimeIndicatorCopyWith on TimeIndicator {
  /// Returns a callable class that can be used as follows: `instanceOfTimeIndicator.copyWith(...)` or like so:`instanceOfTimeIndicator.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TimeIndicatorCWProxy get copyWith => _$TimeIndicatorCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TimeIndicator _$TimeIndicatorFromJson(Map<String, dynamic> json) =>
    TimeIndicator(
      zIndex: (json['zIndex'] as num?)?.toInt() ?? 0,
      height:
          (json['height'] as num?)?.toDouble() ?? defaultTimeIndicatorHeight,
      padding: json['padding'] == null
          ? EdgeInsets.zero
          : const EdgeInsetsConverter()
              .fromJson(json['padding'] as Map<String, dynamic>),
      position: json['position'] == null
          ? DrawPosition.middle
          : const DrawPositionConverter().fromJson(json['position'] as String),
      timeLabel: json['timeLabel'] == null
          ? const TextAreaConfig(
              style: TextStyle(
                  fontSize: defaultTextSize,
                  overflow: TextOverflow.ellipsis,
                  height: defaultTextHeight),
              textWidth: 80,
              textAlign: TextAlign.center)
          : TextAreaConfig.fromJson(json['timeLabel'] as Map<String, dynamic>),
      clipToDrawableRect: json['clipToDrawableRect'] as bool? ?? false,
    );

Map<String, dynamic> _$TimeIndicatorToJson(TimeIndicator instance) =>
    <String, dynamic>{
      'height': instance.height,
      'padding': const EdgeInsetsConverter().toJson(instance.padding),
      'zIndex': instance.zIndex,
      'position': const DrawPositionConverter().toJson(instance.position),
      'timeLabel': instance.timeLabel.toJson(),
      'clipToDrawableRect': instance.clipToDrawableRect,
    };
