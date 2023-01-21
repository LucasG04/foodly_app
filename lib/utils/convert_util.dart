// ignore_for_file: avoid_classes_with_only_static_members

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

class ConvertUtil {
  /// Splits an array into multiple arrays with the length specified by `splitAt`.
  static List<List<dynamic>> splitArray(List<dynamic> array,
      [int splitAt = 10]) {
    final List<List<dynamic>> result = [<dynamic>[]];
    var currentIndex = 0;

    for (var i = 0; i < array.length; i++) {
      result[currentIndex].add(array[i]);
      if ((i + 1) % splitAt == 0) {
        result.add(<dynamic>[]);
        currentIndex++;
      }
    }

    return result;
  }

  /// Converts the amount and the unit (optional) to a better readable string
  static String amountToString(num? amount, [String? unit = '']) {
    amount ??= 0;
    unit ??= '';
    String number = amount.toString();

    if (number.endsWith('.0')) {
      number = number.substring(0, number.indexOf('.'));
    }

    if (number == '0' && unit.isEmpty) {
      return '';
    }

    return '$number $unit'.trim();
  }

  /// Maps a LogRecord to a Map<String, dynamic>
  static Map<String, dynamic> logRecordToMap(LogRecord record) {
    return <String, dynamic>{
      'level': record.level.value,
      'message': record.message,
      'object': jsonEncode(record.object),
      'loggerName': jsonEncode(record.loggerName),
      'time': record.time.toIso8601String(),
      'sequenceNumber': record.sequenceNumber,
      'error': jsonEncode(record.error),
      'stackTrace': jsonEncode(record.stackTrace),
    };
  }

  static num calculateServingsAmount({
    required int requestedServings,
    required int mealServings,
    double? amount,
  }) {
    if (amount == null) {
      return 0;
    }
    if (mealServings == 0) {
      return amount;
    }
    final actualAmount = amount * requestedServings / mealServings;
    return num.tryParse(actualAmount.toStringAsFixed(2)) ?? actualAmount;
  }

  static String errorDescriptionToString(Object? error) {
    return error != null && error is ErrorDescription
        ? error.toStringDeep()
        : error.toString();
  }
}
