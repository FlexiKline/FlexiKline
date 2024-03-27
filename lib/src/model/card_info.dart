import 'package:flutter/material.dart';

class CardInfo {
  CardInfo({
    required this.title,
    required this.titStyle,
    required this.value,
    required this.valStyle,
  });

  final String title;
  final TextStyle titStyle;
  final String value;
  final TextStyle valStyle;
}
