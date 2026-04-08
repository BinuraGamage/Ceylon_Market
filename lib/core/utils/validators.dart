/// Form validator functions.
/// All return null on success, or an error string on failure.
abstract class Validators {
  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) return 'This field is required';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value.trim()))
      return 'Enter a valid email address';
    return null;
  }

  static String? optionalEmail(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value.trim()))
      return 'Enter a valid email address';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone is required';
    final cleaned = value.replaceAll(RegExp(r'\s+'), '');
    if (cleaned.length < 9) return 'Enter a valid phone number';
    return null;
  }

  static String? optionalPhone(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    final cleaned = value.replaceAll(RegExp(r'\s+'), '');
    if (cleaned.length < 9) return 'Enter a valid phone number';
    return null;
  }

  /// Validates LKR amounts — must be a positive number.
  static String? lkrAmount(String? value) {
    if (value == null || value.trim().isEmpty) return 'Amount is required';
    final amount = double.tryParse(value.trim());
    if (amount == null || amount <= 0) return 'Enter a valid LKR amount';
    return null;
  }
}
