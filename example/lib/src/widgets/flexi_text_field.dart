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

import 'package:example/src/theme/flexi_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FlexiTextField extends ConsumerWidget {
  const FlexiTextField({
    super.key,
    required this.controller,
    this.constraints,
    this.textStyle,
    this.textAlignVertical,
    this.width,
    this.height,
    this.focusNode,
    this.isEnable,
    this.bgColor,
    this.margin,
    this.padding,
    this.alignment,
    this.hintText,
    this.hintStyle,
    this.hintMaxLines,
    this.labelText,
    this.labelStyle,
    this.helperText,
    this.helperMaxLines,
    this.helperStyle,
    this.errorText,
    this.errorMaxLines,
    this.errorStyle,
    this.prefixText,
    this.prefixStyle,
    this.suffixText,
    this.suffixStyle,
    this.counterText,
    this.counterStyle,
    this.prefixIcon,
    this.prefixIconConstraints,
    this.suffixIcon,
    this.suffixIconConstraints,
    this.defaultBorderRadius,
    this.border,
    this.enabledBorder,
    this.disabledBorder,
    this.errorBorder,
    this.focusedBorder,
    this.focusedErrorBorder,
    this.autocorrect,
    this.obscureText,
    this.texAlign,
    this.inputFormatters,
    this.onChanged,
    this.maxLength,
    this.minLines,
    this.maxLines,
    this.autofocus = false,
    this.textInputAction,
    this.onSubmitted,
    this.keyboardType,
    this.contentPadding,
    this.decoration,
  });

  final BoxConstraints? constraints;
  final TextEditingController controller;
  final double? width;
  final double? height;
  final FocusNode? focusNode;
  final bool? isEnable;
  final Color? bgColor;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry? alignment;
  final TextAlignVertical? textAlignVertical;
  final TextStyle? textStyle;
  final String? hintText;
  final TextStyle? hintStyle;
  final int? hintMaxLines;
  final String? labelText;
  final TextStyle? labelStyle;
  final String? helperText;
  final int? helperMaxLines;
  final TextStyle? helperStyle;
  final String? errorText;
  final int? errorMaxLines;
  final TextStyle? errorStyle;
  final String? prefixText;
  final TextStyle? prefixStyle;
  final String? suffixText;
  final TextStyle? suffixStyle;
  final String? counterText;
  final TextStyle? counterStyle;
  final Widget? prefixIcon;
  final BoxConstraints? prefixIconConstraints;
  final Widget? suffixIcon;
  final BoxConstraints? suffixIconConstraints;
  final double? defaultBorderRadius;
  final InputBorder? border;
  final InputBorder? enabledBorder;
  final InputBorder? disabledBorder;
  final InputBorder? focusedBorder;
  final InputBorder? errorBorder;
  final InputBorder? focusedErrorBorder;
  final bool? autocorrect;
  final bool? obscureText;
  final TextAlign? texAlign;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final int? maxLength;
  final int? minLines;
  final int? maxLines;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final EdgeInsetsGeometry? contentPadding;
  final BoxDecoration? decoration;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeProvider);
    return Container(
      width: width,
      height: height,
      color: decoration == null ? bgColor : null,
      constraints: constraints,

      ///距离顶部
      margin: margin,
      padding: padding,

      ///Alignment 用来对齐 Widget
      alignment: alignment,

      decoration: decoration,

      ///文本输入框
      child: TextField(
        style: textStyle ?? theme.t1s14w400,
        controller: controller,

        //最多文字数量
        maxLength: maxLength,

        // 多行
        maxLines: maxLines,
        minLines: minLines,

        textAlignVertical: textAlignVertical ?? TextAlignVertical.center,
        textCapitalization: TextCapitalization.none,

        // true: 自动对焦，第一次进来就弹起键盘
        autofocus: autofocus,

        keyboardType: keyboardType,

        //同样是点击键盘完成按钮时触发的回调，该回调有参数，参数即为当前输入框中的值。(String)
        onSubmitted: onSubmitted,

        // 修改键盘右小角按钮文字或图标（textInputAction: TextInputAction.go,）
        textInputAction: textInputAction,

        ///是否可编辑
        enabled: isEnable,

        ///焦点获取
        focusNode: focusNode,

        // 光标颜色
        cursorColor: theme.brand,

        autocorrect: autocorrect ?? false,

        obscuringCharacter: '*',

        obscureText: obscureText ?? false,

        ///text对齐方式
        textAlign: texAlign ?? TextAlign.start,

        inputFormatters: inputFormatters,

        onChanged: onChanged,

        ///用来配置 TextField 的样式风格
        decoration: InputDecoration(
          contentPadding: contentPadding,

          isDense: true,

          ///设置输入文本框的提示文字
          ///输入框获取焦点时 并且没有输入文字时
          hintText: hintText,

          ///设置输入文本框的提示文字最大行数
          hintMaxLines: hintMaxLines,

          ///设置输入文本框的提示文字的样式
          hintStyle: hintStyle ?? theme.t3s14w400,

          ///输入框内的提示 输入框没有获取焦点时显示
          labelText: labelText,
          labelStyle: labelStyle ?? theme.t1s14w400,

          ///显示在输入框下面的文字
          helperText: helperText,
          helperMaxLines: helperMaxLines,
          helperStyle: helperStyle,

          ///显示在输入框下面的文字
          ///会覆盖了 helperText 内容
          errorText: errorText,
          errorMaxLines: errorMaxLines,
          errorStyle: errorStyle ?? theme.tss12w400,

          ///输入框获取焦点时才会显示出来 输入文本的前面
          prefixText: prefixText,
          prefixStyle: prefixStyle,

          ///输入框获取焦点时才会显示出来 输入文本的后面
          suffixText: suffixText,
          suffixStyle: suffixStyle,

          ///文本输入框右下角显示的文本
          ///文字计数器默认使用
          counterText: counterText,
          counterStyle: counterStyle,

          ///输入文字前的小图标
          prefixIcon: prefixIcon,
          prefixIconConstraints: prefixIconConstraints,

          ///输入文字后面的小图标
          suffixIcon: suffixIcon,
          suffixIconConstraints: suffixIconConstraints,

          ///与 prefixText 不能同时设置
//                prefix: Text("A") ,
          /// 与 suffixText 不能同时设置
//                suffix:  Text("B") ,
          ///设置边框
          ///   InputBorder.none 无下划线
          ///   OutlineInputBorder 上下左右 都有边框
          ///   UnderlineInputBorder 只有下边框  默认使用的就是下边框
          border: border ??
              genOutlineBorder(
                color: theme.borderLine,
                radius: defaultBorderRadius,
              ),

          ///设置输入框可编辑时的边框样式
          enabledBorder: enabledBorder ??
              genOutlineBorder(
                color: theme.borderLine,
                radius: defaultBorderRadius,
              ),

          ///设置输入框禁用时的边框样式
          disabledBorder: disabledBorder ??
              genOutlineBorder(
                color: theme.disable,
                radius: defaultBorderRadius,
              ),

          ///用来配置输入框获取错误焦点时的颜色
          errorBorder: errorBorder ??
              genOutlineBorder(
                color: theme.error,
                radius: defaultBorderRadius,
              ),

          ///用来配置输入框获取错误焦点时的颜色
          focusedErrorBorder: focusedErrorBorder ??
              genOutlineBorder(
                color: theme.error,
                radius: defaultBorderRadius,
              ),

          ///用来配置输入框获取焦点时的颜色
          focusedBorder: focusedBorder ??
              genOutlineBorder(
                color: theme.t1,
                radius: defaultBorderRadius,
              ),
        ),
      ),
    );
  }
}

InputBorder genOutlineBorder({
  double? radius,
  required Color color,
  double? width,
}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(radius ?? 6.r),
    borderSide: BorderSide(
      color: color,
      width: width ?? 1.r,
    ),
  );
}
