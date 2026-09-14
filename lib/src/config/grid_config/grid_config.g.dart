// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grid_config.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GridConfigCWProxy {
  GridConfig horizontal(GridBorder horizontal);

  GridConfig vertical(GridBorder vertical);

  GridConfig isAllowDragIndicatorHeight(bool isAllowDragIndicatorHeight);

  GridConfig dragHitTestMinDistance(double dragHitTestMinDistance);

  GridConfig draggingBgOpacity(double draggingBgOpacity);

  GridConfig dragBgOpacity(double dragBgOpacity);

  GridConfig dragLine(LineConfig? dragLine);

  GridConfig dragLineOpacity(double dragLineOpacity);

  GridConfig ticksText(TextAreaConfig ticksText);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `GridConfig(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GridConfig(...).copyWith(id: 12, name: "My name")
  /// ```
  GridConfig call({
    GridBorder horizontal,
    GridBorder vertical,
    bool isAllowDragIndicatorHeight,
    double dragHitTestMinDistance,
    double draggingBgOpacity,
    double dragBgOpacity,
    LineConfig? dragLine,
    double dragLineOpacity,
    TextAreaConfig ticksText,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGridConfig.copyWith(...)` or call `instanceOfGridConfig.copyWith.fieldName(value)` for a single field.
class _$GridConfigCWProxyImpl implements _$GridConfigCWProxy {
  const _$GridConfigCWProxyImpl(this._value);

  final GridConfig _value;

  @override
  GridConfig horizontal(GridBorder horizontal) => call(horizontal: horizontal);

  @override
  GridConfig vertical(GridBorder vertical) => call(vertical: vertical);

  @override
  GridConfig isAllowDragIndicatorHeight(bool isAllowDragIndicatorHeight) =>
      call(isAllowDragIndicatorHeight: isAllowDragIndicatorHeight);

  @override
  GridConfig dragHitTestMinDistance(double dragHitTestMinDistance) =>
      call(dragHitTestMinDistance: dragHitTestMinDistance);

  @override
  GridConfig draggingBgOpacity(double draggingBgOpacity) =>
      call(draggingBgOpacity: draggingBgOpacity);

  @override
  GridConfig dragBgOpacity(double dragBgOpacity) =>
      call(dragBgOpacity: dragBgOpacity);

  @override
  GridConfig dragLine(LineConfig? dragLine) => call(dragLine: dragLine);

  @override
  GridConfig dragLineOpacity(double dragLineOpacity) =>
      call(dragLineOpacity: dragLineOpacity);

  @override
  GridConfig ticksText(TextAreaConfig ticksText) => call(ticksText: ticksText);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `GridConfig(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GridConfig(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GridConfig call({
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
      horizontal:
          horizontal == const $CopyWithPlaceholder() || horizontal == null
          ? _value.horizontal
          // ignore: cast_nullable_to_non_nullable
          : horizontal as GridBorder,
      vertical: vertical == const $CopyWithPlaceholder() || vertical == null
          ? _value.vertical
          // ignore: cast_nullable_to_non_nullable
          : vertical as GridBorder,
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
      draggingBgOpacity:
          draggingBgOpacity == const $CopyWithPlaceholder() ||
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
      dragLineOpacity:
          dragLineOpacity == const $CopyWithPlaceholder() ||
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
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGridConfig.copyWith(...)` or `instanceOfGridConfig.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GridConfigCWProxy get copyWith => _$GridConfigCWProxyImpl(this);
}

abstract class _$GridBorderCWProxy {
  GridBorder show(bool show);

  GridBorder line(LineConfig line);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `GridBorder(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GridBorder(...).copyWith(id: 12, name: "My name")
  /// ```
  GridBorder call({bool show, LineConfig line});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGridBorder.copyWith(...)` or call `instanceOfGridBorder.copyWith.fieldName(value)` for a single field.
class _$GridBorderCWProxyImpl implements _$GridBorderCWProxy {
  const _$GridBorderCWProxyImpl(this._value);

  final GridBorder _value;

  @override
  GridBorder show(bool show) => call(show: show);

  @override
  GridBorder line(LineConfig line) => call(line: line);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `GridBorder(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GridBorder(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GridBorder call({
    Object? show = const $CopyWithPlaceholder(),
    Object? line = const $CopyWithPlaceholder(),
  }) {
    return GridBorder(
      show: show == const $CopyWithPlaceholder() || show == null
          ? _value.show
          // ignore: cast_nullable_to_non_nullable
          : show as bool,
      line: line == const $CopyWithPlaceholder() || line == null
          ? _value.line
          // ignore: cast_nullable_to_non_nullable
          : line as LineConfig,
    );
  }
}

extension $GridBorderCopyWith on GridBorder {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGridBorder.copyWith(...)` or `instanceOfGridBorder.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GridBorderCWProxy get copyWith => _$GridBorderCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GridConfig _$GridConfigFromJson(Map<String, dynamic> json) => GridConfig(
  horizontal: json['horizontal'] == null
      ? const GridBorder()
      : GridBorder.fromJson(json['horizontal'] as Map<String, dynamic>),
  vertical: json['vertical'] == null
      ? const GridBorder()
      : GridBorder.fromJson(json['vertical'] as Map<String, dynamic>),
  isAllowDragIndicatorHeight:
      json['isAllowDragIndicatorHeight'] as bool? ?? false,
  dragHitTestMinDistance:
      (json['dragHitTestMinDistance'] as num?)?.toDouble() ?? 10,
  draggingBgOpacity: (json['draggingBgOpacity'] as num?)?.toDouble() ?? 0.1,
  dragBgOpacity: (json['dragBgOpacity'] as num?)?.toDouble() ?? 0,
  dragLine: json['dragLine'] == null
      ? const LineConfig(
          type: LineType.dashed,
          dashes: [3, 5],
          length: 20,
          paint: PaintConfig(strokeWidth: 2),
        )
      : LineConfig.fromJson(json['dragLine'] as Map<String, dynamic>),
  dragLineOpacity: (json['dragLineOpacity'] as num?)?.toDouble() ?? 0.1,
  ticksText: json['ticksText'] == null
      ? const TextAreaConfig(
          style: TextStyle(
            fontSize: defaultTextSize,
            overflow: TextOverflow.ellipsis,
            height: defaultTextHeight,
          ),
          textAlign: TextAlign.end,
          padding: EdgeInsets.symmetric(horizontal: 2),
        )
      : TextAreaConfig.fromJson(json['ticksText'] as Map<String, dynamic>),
);

Map<String, dynamic> _$GridConfigToJson(GridConfig instance) =>
    <String, dynamic>{
      'horizontal': instance.horizontal.toJson(),
      'vertical': instance.vertical.toJson(),
      'isAllowDragIndicatorHeight': instance.isAllowDragIndicatorHeight,
      'dragHitTestMinDistance': instance.dragHitTestMinDistance,
      'dragLine': ?instance.dragLine?.toJson(),
      'dragLineOpacity': instance.dragLineOpacity,
      'draggingBgOpacity': instance.draggingBgOpacity,
      'dragBgOpacity': instance.dragBgOpacity,
      'ticksText': instance.ticksText.toJson(),
    };

GridBorder _$GridBorderFromJson(Map<String, dynamic> json) => GridBorder(
  show: json['show'] as bool? ?? true,
  line: json['line'] == null
      ? const LineConfig(
          type: LineType.solid,
          dashes: [2, 2],
          paint: PaintConfig(strokeWidth: defaultAuxiliaryLineWidth),
        )
      : LineConfig.fromJson(json['line'] as Map<String, dynamic>),
);

Map<String, dynamic> _$GridBorderToJson(GridBorder instance) =>
    <String, dynamic>{'show': instance.show, 'line': instance.line.toJson()};
