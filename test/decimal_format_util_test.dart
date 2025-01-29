// ignore_for_file: always_put_control_body_on_new_line

import 'package:flexi_kline/src/extension/decimal_ext.dart';
import 'package:flexi_kline/src/utils/decimal_format_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('test zeroPadding', () {
    const list = <String>[
      '100000',
      '1.123',
      '1.0123',
      '1.00123',
      '1.000123',
      '1.0000123',
      '1.00000123',
      '1.0000000',
    ];
    for (final str in list) {
      debugPrint('$str\t=>\t${formatNumber(
        str.d,
        precision: 10,
        cutInvalidZero: true,
        useZeroPadding: true,
      )}');
    }
  });

  test('test formatPercentage', () {
    var result = formatPercentage(0.1, cutInvalidZero: false);
    expect(result, "10.00%");
    result = formatPercentage(0.1, cutInvalidZero: true);
    expect(result, "10%");

    result = formatPercentage(0.98765, cutInvalidZero: false);
    expect(result, "98.76%");
    result = formatPercentage(0.98765, cutInvalidZero: true);
    expect(result, "98.76%");
  });

  test('test formatPrice', () {
    var result =
        formatPrice(0.1.d, precision: 2, cutInvalidZero: false, prefix: '\$');
    expect(result, "\$0.10");
    result =
        formatPrice(0.1.d, precision: 2, cutInvalidZero: true, prefix: '\$');
    expect(result, "\$0.1");

    result = formatPrice(123456.789.d, precision: 2, prefix: '\$');
    expect(result, "\$123,456.78");

    result = formatPrice(123456.000000789.d, precision: 9, prefix: '\$');
    expect(result, "\$123,456.0{6}789");
  });

  test('test formatAmount', () {
    var result = formatAmount(12345.1.d, precision: 2);
    expect(result, "12.35K");

    result = formatAmount(123456789.d, precision: 3);
    expect(result, "123.457M");
  });

  test('test formatNumber', () {
    FormatDecimal.thousandSeparator = '.';
    var result = formatNumber(
      123456.000000789.d,
      precision: 100,
      cutInvalidZero: true,
      showThousands: true,
      useZeroPadding: true,
      prefix: '\$',
      suffix: 'USDT',
      showSign: true,
    );
    expect(result, "\$+123.456.0{6}789USDT");
  });
}
