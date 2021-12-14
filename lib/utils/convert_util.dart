class ConvertUtil {
  /// Splits an array into multiple arrays with the length specified by `splitAt`.
  static List<List<dynamic>> splitArray(List<dynamic> array,
      [int splitAt = 10]) {
    var result = [[]];
    var currentIndex = 0;

    for (var i = 0; i < array.length; i++) {
      result[currentIndex].add(array[i]);
      if ((i + 1) % splitAt == 0) {
        result.add([]);
        currentIndex++;
      }
    }

    return result;
  }

  /// Converts the amount and the unit (optional) to a good readable string
  static String amountToString(double? amount, [String? unit = '']) {
    String number = amount.toString();
    if (number.endsWith('0')) {
      number = number.substring(0, number.indexOf('.'));
    }

    if (number == '0') {
      number = '';
    }

    String result = '$number $unit';
    result.trim();

    return result;
  }
}
