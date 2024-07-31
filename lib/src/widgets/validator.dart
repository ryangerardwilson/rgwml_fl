class Validator {
  static String? validateField(String field, String? value, List<String> rules) {
    bool isRequired = rules.contains('REQUIRED');

    for (String rule in rules) {
      List<String> parts = rule.split(':');
      String ruleName = parts[0];
      List<String> params = parts.sublist(1);

      switch (ruleName) {
        case 'REQUIRED':
          if (value == null || value.isEmpty) {
            return '$field is required.';
          }
          break;
        case 'CHAR_LENGTH':
          int length = int.parse(params[0]);
          if (value!.length != length) {
            return '$field must be $length characters long.';
          }
          break;
        case 'IS_NUMERICALLY_PARSEABLE':
          if (double.tryParse(value!) == null) {
            return '$field must be numerically parseable.';
          }
          break;
        case 'IS_INDIAN_MOBILE_NUMBER':
          if (!isRequired && (value == null || value.isEmpty)) {
            break;  // Skip if not required and empty
          }
          RegExp regex = RegExp(r'^[6789]\d{9}$');
          if (!regex.hasMatch(value!) || value.split('').toSet().length < 4) {
            return '$field must be a valid Indian mobile number.';
          }
          break;
        case 'IS_YYYY-MM-DD':
          RegExp dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
          if (!dateRegex.hasMatch(value!)) {
            return '$field must be in YYYY-MM-DD format.';
          }
          break;
        case 'IS_AFTER_TODAY':
          if (!isRequired && (value == null || value.isEmpty)) {
            break;  // Skip if not required and empty
          }
          DateTime today = DateTime.now();
          DateTime enteredDate;
          try {
            enteredDate = DateTime.parse(value!);
          } catch (_) {
            return '$field must be a valid date.';
          }
          if (enteredDate.isBefore(today) || enteredDate.isAtSameMomentAs(today)) {
            return '$field must be a date after today.';
          }
          break;
        case 'IS_BEFORE_TODAY':
          if (!isRequired && (value == null || value.isEmpty)) {
            break;  // Skip if not required and empty
          }
          DateTime today = DateTime.now();
          DateTime enteredDate;
          try {
            enteredDate = DateTime.parse(value!);
          } catch (_) {
            return '$field must be a valid date.';
          }
          if (enteredDate.isAfter(today) || enteredDate.isAtSameMomentAs(today)) {
            return '$field must be a date before today.';
          }
          break;
        default:
          break;
      }
    }
    return null;
  }
}

