// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grid_config.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GridConfigCWProxy {
  GridConfig show(bool show);

  GridConfig horizontal(GridAxis horizontal);

  GridConfig vertical(GridAxis vertical);

  GridConfig isAllowDragIndicatorHeight(bool isAllowDragIndicatorHeight);

  GridConfig dragHitTestMinDistance(double dragHitTestMinDistance);

  GridConfig draggingBgOpacity(double draggingBgOpacity);

  GridConfig dragBgOpacity(double dragBgOpacity);

  GridConfig dragLine(LineConfig? dragLine);

  GridConfig dragLineOpacity(double dragLineOpacity);

  GridConfig ticksText(TextAreaConfig ticksText);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `GridConfig(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// GridConfig(...).copyWith(id: 12, name: "My name")
  /// ````
  GridConfig call({
    bool? show,
    GridAxis? horizontal,
    GridAxis? vertical,
    bool? isAllowDragIndicatorHeight,
    double? dragHitTestMinDistance,
    double? draggingBgOpacity,
    double? dragBgOpacity,
    LineConfig? dragLine,
    double? dragLineOpacity,
    TextAreaConfig? ticksText,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfGridConfig.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfGridConfig.copyWith.fieldName(...)`
class _$GridConfigCWProxyImpl implements _$GridConfigCWProxy {
  const _$GridConfigCWProxyImpl(this._value);

  final GridConfig _value;

  @override
  GridConfig show(bool show) => this(show: show);

  @override
  GridConfig horizontal(GridAxis horizontal) => this(horizontal: horizontal);

  @override
  GridConfig vertical(GridAxis vertical) => this(vertical: vertical);

  @override
  GridConfig isAllowDragIndicatorHeight(bool isAllowDragIndicatorHeight) =>
      this(isAllowDragIndicatorHeight: isAllowDragIndicatorHeight);

  @override
  GridConfig dragHitTestMinDistance(double dragHitTestMinDistance) =>
      this(dragHitTestMinDistance: dragHitTestMinDistance);

  @override
  GridConfig draggingBgOpacity(double draggingBgOpacity) =>
      this(draggingBgOpacity: draggingBgOpacity);

  @override
  GridConfig dragBgOpacity(double dragBgOpacity) =>
      this(dragBgOpacity: dragBgOpacity);

  @override
  GridConfig dragLine(LineConfig? dragLine) => this(dragLine: dragLine);

  @override
  GridConfig dragLineOpacity(double dragLineOpacity) =>
      this(dragLineOpacity: dragLineOpacity);

  @override
  GridConfig ticksText(TextAreaConfig ticksText) => this(ticksText: ticksText);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `GridConfig(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// GridConfig(...).copyWith(id: 12, name: "My name")
  /// ````
  GridConfig call({
    Object? show = const $CopyWithPlaceholder(),
    Object? horizontal = const $CopyWithPlaceholder(),
    Object? vertical = const $CopyWithPlaceholder(),
    Object? isAllowDragIndicatorHeight = const $CopyWithPlaceholder(),
    Object? dragHitTestMinDistance = const $CopyWithPlaceholder(),
    Object? draggingBgOpacity = const $CopyWithPlaceholder(),
    Object? dragBgOpacity = const $CopyWithPlaceholder(),
    Object? dragLine = const $CopyWithPlaceholder(),
    Object? dragLineOpacity = const $CopyWithPlaceholder(),
    Object? ticksText = const $CopyWithPlaceholder(),
  }) {
    return GridConfig(
      show: show == const $CopyWithPlaceholder() || show == null
          ? _value.show
          // ignore: cast_nullable_to_non_nullable
          : show as bool,
      horizontal:
          horizontal == const $CopyWithPlaceholder() || horizontal == null
              ? _value.horizontal
              // ignore: cast_nullable_to_non_nullable
              : horizontal as GridAxis,
      vertical: vertical == const $CopyWithPlaceholder() || vertical == null
          ? _value.vertical
          // ignore: cast_nullable_to_non_nullable
          : vertical as GridAxis,
      isAllowDragIndicatorHeight:
          isAllowDragIndicatorHeight == const $CopyWithPlaceholder() ||
                  isAllowDragIndicatorHeight == null
              ? _value.isAllowDragIndicatorHeight
              // ignore: cast_nullable_to_non_nullable
              : isAllowDragIndicatorHeight as bool,
      dragHitTestMinDistance:
          dragHitTestMinDistance == const $CopyWithPlaceholder() ||
                  dragHitTestMinDistance == null
              ? _value.dragHitTestMinDistance
              // ignore: cast_nullable_to_non_nullable
              : dragHitTestMinDistance as double,
      draggingBgOpacity: draggingBgOpacity == const $CopyWithPlaceholder() ||
              draggingBgOpacity == null
          ? _value.draggingBgOpacity
          // ignore: cast_nullable_to_non_nullable
          : draggingBgOpacity as double,
      dragBgOpacity:
          dragBgOpacity == const $CopyWithPlaceholder() || dragBgOpacity == null
              ? _value.dragBgOpacity
              // ignore: cast_nullable_to_non_nullable
              : dragBgOpacity as double,
      dragLine: dragLine == const $CopyWithPlaceholder()
          ? _value.dragLine
          // ignore: cast_nullable_to_non_nullable
          : dragLine as LineConfig?,
      dragLineOpacity: dragLineOpacity == const $CopyWithPlaceholder() ||
              dragLineOpacity == null
          ? _value.dragLineOpacity
          // ignore: cast_nullable_to_non_nullable
          : dragLineOpacity as double,
      ticksText: ticksText == const $CopyWithPlaceholder() || ticksText == null
          ? _value.ticksText
          // ignore: cast_nullable_to_non_nullable
          : ticksText as TextAreaConfig,
    );
  }
}

extension $GridConfigCopyWith on GridConfig {
  /// Returns a callable class that can be used as follows: `instanceOfGridConfig.copyWith(...)` or like so:`instanceOfGridConfig.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GridConfigCWProxy get copyWith => _$GridConfigCWProxyImpl(this);
}

abstract class _$GridAxisCWProxy {
  GridAxis show(bool show);

  GridAxis count(int count);

  GridAxis line(LineConfig line);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `GridAxis(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// GridAxis(...).copyWith(id: 12, name: "My name")
  /// ````
  GridAxis call({
    bool? show,
    int? count,
    LineConfig? line,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfGridAxis.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfGridAxis.copyWith.fieldName(...)`
class _$GridAxisCWProxyImpl implements _$GridAxisCWProxy {
  const _$GridAxisCWProxyImpl(this._value);

  final GridAxis _value;

  @override
  GridAxis show(bool show) => this(show: show);

  @override
  GridAxis count(int count) => this(count: count);

  @override
  GridAxis line(LineConfig line) => this(line: line);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `GridAxis(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// GridAxis(...).copyWith(id: 12, name: "My name")
  /// ````
  GridAxis call({
    Object? show = const $CopyWithPlaceholder(),
    Object? count = const $CopyWithPlaceholder(),
    Object? line = const $CopyWithPlaceholder(),
  }) {
    return GridAxis(
      show: show == const $CopyWithPlaceholder() || show == null
          ? _value.show
          // ignore: cast_nullable_to_non_nullable
          : show as bool,
      count: count == const $CopyWithPlaceholder() || count == null
          ? _value.count
          // ignore: cast_nullable_to_non_nullable
          : count as int,
      line: line == const $CopyWithPlaceholder() || line == null
          ? _value.line
          // ignore: cast_nullable_to_non_nullable
          : line as LineConfig,
    );
  }
}

extension $GridAxisCopyWith on GridAxis {
  /// Returns a callable class that can be used as follows: `instanceOfGridAxis.copyWith(...)` or like so:`instanceOfGridAxis.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GridAxisCWProxy get copyWith => _$GridAxisCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GridConfig _$GridConfigFromJson(Map<String, dynamic> json) => GridConfig(
      show: json['show'] as bool? ?? true,
      horizontal: json['horizontal'] == null
          ? const GridAxis()
          : GridAxis.fromJson(json['horizontal'] as Map<String, dynamic>),
      vertical: json['vertical'] == null
          ? const GridAxis()
          : GridAxis.fromJson(json['vertical'] as Map<String, dynamic>),
      isAllowDragIndicatorHeight:
          json['isAllowDragIndicatorHeight'] as bool? ?? true,
      dragHitTestMinDistance:
          (json['dragHitTestMinDistance'] as num?)?.toDouble() ?? 10,
      draggingBgOpacity: (json['draggingBgOpacity'] as num?)?.toDouble() ?? 0.1,
      dragBgOpacity: (json['dragBgOpacity'] as num?)?.toDouble() ?? 0,
      dragLine: json['dragLine'] == null
          ? null
          : LineConfig.fromJson(json['dragLine'] as Map<String, dynamic>),
      dragLineOpacity: (json['dragLineOpacity'] as num?)?.toDouble() ?? 0.1,
      ticksText:
          TextAreaConfig.fromJson(json['ticksText'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GridConfigToJson(GridConfig instance) {
  final val = <String, dynamic>{
    'show': instance.show,
    'horizontal': instance.horizontal.toJson(),
    'vertical': instance.vertical.toJson(),
    'isAllowDragIndicatorHeight': instance.isAllowDragIndicatorHeight,
    'dragHitTestMinDistance': instance.dragHitTestMinDistance,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('dragLine', instance.dragLine?.toJson());
  val['dragLineOpacity'] = instance.dragLineOpacity;
  val['draggingBgOpacity'] = instance.draggingBgOpacity;
  val['dragBgOpacity'] = instance.dragBgOpacity;
  val['ticksText'] = instance.ticksText.toJson();
  return val;
}

GridAxis _$GridAxisFromJson(Map<String, dynamic> json) => GridAxis(
      show: json['show'] as bool? ?? true,
      count: (json['count'] as num?)?.toInt() ?? 5,
      line: json['line'] == null
          ? const LineConfig(
              type: LineType.solid,
              dashes: [2, 2],
              paint: PaintConfig(strokeWidth: 0.5))
          : LineConfig.fromJson(json['line'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GridAxisToJson(GridAxis instance) => <String, dynamic>{
      'show': instance.show,
      'count': instance.count,
      'line': instance.line.toJson(),
    };
