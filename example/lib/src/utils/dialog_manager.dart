import 'package:example/src/theme/export.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

final class DialogManager {
  DialogManager._internal();
  factory DialogManager() => _instance;
  static final _instance = DialogManager._internal();
  static DialogManager get instance => _instance;

  Future<T?> showCenterDialog<T>({
    BuildContext? context,
    required WidgetBuilder builder,
    String? dialogTag,
    bool keepSingle = true,
    bool backDismiss = false,
    bool clickMaskDismiss = true,
    Color? bgColor,
    EdgeInsetsGeometry? margin,
  }) {
    return show<T>(
      alignment: Alignment.center,
      dialogTag: dialogTag,
      keepSingle: keepSingle,
      backDismiss: backDismiss,
      clickMaskDismiss: clickMaskDismiss,
      context: context,
      builder: builder,
      bgColor: bgColor,
      margin: margin ?? EdgeInsetsDirectional.all(20.r),
    );
  }

  Future<T?> showBottomDialog<T>({
    BuildContext? context,
    required WidgetBuilder builder,
    String? dialogTag,
    bool keepSingle = true,
    bool backDismiss = false,
    bool clickMaskDismiss = true,
    Color? bgColor,
  }) {
    return show<T>(
      alignment: Alignment.bottomCenter,
      dialogTag: dialogTag,
      keepSingle: keepSingle,
      backDismiss: backDismiss,
      clickMaskDismiss: clickMaskDismiss,
      context: context,
      builder: builder,
      bgColor: bgColor,
    );
  }

  Future<T?> showDialogPermanent<T>({
    BuildContext? context,
    required WidgetBuilder builder,
    String? dialogTag,
    bool keepSingle = true,
    bool backDismiss = false,
    bool clickMaskDismiss = true,
    Alignment alignment = Alignment.bottomCenter,
    EdgeInsetsGeometry? margin,
  }) {
    return show<T>(
      alignment: alignment,
      dialogTag: dialogTag,
      keepSingle: keepSingle,
      backDismiss: backDismiss,
      clickMaskDismiss: clickMaskDismiss,
      // bindPage: true,
      context: context,
      onMask: () {
        SmartDialog.dismiss(
          tag: dialogTag,
          force: true,
        );
      },
      permanent: true, //newInfo.forceUpdate, // 永久驻留
      builder: builder,
    );
  }

  Future<T?> show<T>({
    BuildContext? context,
    required WidgetBuilder builder,
    String? dialogTag,
    bool keepSingle = true,
    bool backDismiss = false,
    bool clickMaskDismiss = true,
    bool? bindPage,
    bool? permanent,
    bool? usePenetrate,
    bool? useAnimation,
    SmartAnimationType? animationType,
    Color? bgColor,
    double? radius,
    Alignment alignment = Alignment.bottomCenter,
    VoidCallback? onMask,
    EdgeInsetsGeometry? margin,
  }) {
    return SmartDialog.show<T>(
      alignment: alignment,
      tag: dialogTag,
      keepSingle: keepSingle,
      // backDismiss: backDismiss,
      backType: SmartBackType.normal,
      clickMaskDismiss: clickMaskDismiss,
      bindPage: bindPage,
      bindWidget: context,
      permanent: permanent, // 永久驻留
      usePenetrate: usePenetrate,
      useAnimation: useAnimation,
      animationType: animationType,
      onMask: onMask,
      builder: (context) => DialogWrapper(
        key: ValueKey(dialogTag),
        margin: margin,
        bgColor: bgColor,
        alignment: alignment,
        radius: radius,
        child: builder(context),
      ),
    );
  }
}

class DialogWrapper extends ConsumerWidget {
  const DialogWrapper({
    super.key,
    required this.child,
    this.bgColor,
    this.radius,
    required this.alignment,
    this.margin,
  });
  final Widget child;
  final Color? bgColor;
  final double? radius;
  final Alignment alignment;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    BorderRadius borderRadius;
    if (alignment == Alignment.topCenter) {
      borderRadius = BorderRadius.only(
        bottomLeft: Radius.circular(radius ?? 8.r),
        bottomRight: Radius.circular(radius ?? 8.r),
      );
    } else if (alignment == Alignment.bottomCenter) {
      borderRadius = BorderRadius.only(
        topLeft: Radius.circular(radius ?? 8.r),
        topRight: Radius.circular(radius ?? 8.r),
      );
    } else {
      borderRadius = BorderRadius.circular(radius ?? 8.r);
    }

    final contnet = Material(
      borderRadius: borderRadius,
      color: bgColor ?? ref.read(themeProvider).pageBg,
      child: SafeArea(
        top: false,
        child: child,
      ),
    );

    if (margin != null) {
      return Container(
        margin: margin,
        child: contnet,
      );
    }
    return contnet;
  }
}
