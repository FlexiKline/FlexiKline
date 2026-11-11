import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

/// 大标题 + 右下角小标签：标签用品牌色底、白色小字，底边与标题的文字底边对齐。
class TitleWithTag extends StatelessWidget {
  const TitleWithTag(this.title, {super.key, required this.tag});

  final String title;
  final String tag;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      spacing: 4,
      children: [
        Text(title),
        DecoratedBox(
          decoration: BoxDecoration(color: AppTheme.brandBlue, borderRadius: BorderRadius.circular(3)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            child: Text(
              tag,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                height: 1.2,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
