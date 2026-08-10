String userAccessTemporaryNumber(DateTime now) {
  final digits = <String>[];
  for (var position = 1; position <= 8; position++) {
    final seed = position * 9637 + 33;
    var digit =
        (now.hour + now.minute + now.second + seed + 9) % 10;
    if (digit == 0) digit = 1;
    digits.add(digit.toString());
  }
  return digits.join();
}

String userAccessSerialNumber(String temporaryNumber) {
  var encoded = int.parse(temporaryNumber);
  for (var index = 0; index < temporaryNumber.length; index++) {
    var digit = int.parse(temporaryNumber[index]);
    if (digit == 0) digit = 1;

    switch (index) {
      case 1:
        encoded ~/= digit;
      case 2:
        encoded += digit;
      case 5:
        encoded *= digit;
      case 6:
        encoded -= digit;
    }
  }
  return encoded.toString();
}

String userAccessLocalValue(String accessData) {
  return '${userAccessSerialNumber(accessData.substring(0, 8))}'
      '${userAccessSerialNumber(accessData.substring(8))}';
}