const String kEmergencySameAsOwnError =
    'Emergency contact number cannot be your own number. Please add a different number.';

String phoneDigitsKey(String? value) {
  final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
  return digits.length > 10 ? digits.substring(digits.length - 10) : digits;
}

bool samePhoneNumber(String? a, String? b) {
  final x = phoneDigitsKey(a);
  final y = phoneDigitsKey(b);
  return x.length == 10 && x == y;
}
