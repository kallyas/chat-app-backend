import '../utils/constants.dart';

class Validators {
  // Email validation
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return AppConstants.emailRequiredMessage;
    }
    
    if (!AppConstants.emailRegex.hasMatch(email)) {
      return AppConstants.emailInvalidMessage;
    }
    
    return null;
  }

  // Password validation
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return AppConstants.passwordRequiredMessage;
    }
    
    if (password.length < AppConstants.minPasswordLength) {
      return AppConstants.passwordTooShortMessage;
    }
    
    return null;
  }

  // Username validation
  static String? validateUsername(String? username) {
    if (username == null || username.isEmpty) {
      return AppConstants.usernameRequiredMessage;
    }
    
    if (!AppConstants.usernameRegex.hasMatch(username)) {
      return AppConstants.usernameInvalidMessage;
    }
    
    return null;
  }

  // Confirm password validation
  static String? validateConfirmPassword(String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (password != confirmPassword) {
      return AppConstants.passwordMismatchMessage;
    }
    
    return null;
  }

  // Message validation
  static String? validateMessage(String? message) {
    if (message == null || message.trim().isEmpty) {
      return AppConstants.messageRequiredMessage;
    }
    
    if (message.length > AppConstants.maxMessageLength) {
      return AppConstants.messageTooLongMessage;
    }
    
    return null;
  }

  // Chat room name validation
  static String? validateChatRoomName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'Chat room name is required';
    }
    
    if (name.length > AppConstants.maxChatRoomNameLength) {
      return 'Chat room name is too long (max ${AppConstants.maxChatRoomNameLength} characters)';
    }
    
    return null;
  }

  // Chat room description validation
  static String? validateChatRoomDescription(String? description) {
    if (description != null && description.length > AppConstants.maxChatRoomDescriptionLength) {
      return 'Description is too long (max ${AppConstants.maxChatRoomDescriptionLength} characters)';
    }
    
    return null;
  }

  // Phone number validation
  static String? validatePhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) {
      return 'Phone number is required';
    }
    
    if (!AppConstants.phoneRegex.hasMatch(phone)) {
      return 'Please enter a valid phone number';
    }
    
    return null;
  }

  // Name validation (for display names, etc.)
  static String? validateName(String? name, {String fieldName = 'Name'}) {
    if (name == null || name.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    if (name.trim().length < 2) {
      return '$fieldName must be at least 2 characters';
    }
    
    if (name.trim().length > 50) {
      return '$fieldName is too long (max 50 characters)';
    }
    
    return null;
  }

  // URL validation
  static String? validateUrl(String? url) {
    if (url == null || url.isEmpty) {
      return null; // URL is optional
    }
    
    if (!AppConstants.urlRegex.hasMatch(url)) {
      return 'Please enter a valid URL';
    }
    
    return null;
  }

  // Required field validation
  static String? validateRequired(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // Minimum length validation
  static String? validateMinLength(String? value, int minLength, {String fieldName = 'Field'}) {
    if (value == null || value.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    return null;
  }

  // Maximum length validation
  static String? validateMaxLength(String? value, int maxLength, {String fieldName = 'Field'}) {
    if (value != null && value.length > maxLength) {
      return '$fieldName must be no more than $maxLength characters';
    }
    return null;
  }

  // Numeric validation
  static String? validateNumeric(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    if (double.tryParse(value) == null) {
      return '$fieldName must be a valid number';
    }
    
    return null;
  }

  // Positive number validation
  static String? validatePositiveNumber(String? value, {String fieldName = 'Field'}) {
    final numericError = validateNumeric(value, fieldName: fieldName);
    if (numericError != null) return numericError;
    
    final number = double.parse(value!);
    if (number <= 0) {
      return '$fieldName must be a positive number';
    }
    
    return null;
  }

  // Age validation
  static String? validateAge(String? age) {
    final numericError = validatePositiveNumber(age, fieldName: 'Age');
    if (numericError != null) return numericError;
    
    final ageValue = int.parse(age!);
    if (ageValue < 13) {
      return 'You must be at least 13 years old';
    }
    
    if (ageValue > 120) {
      return 'Please enter a valid age';
    }
    
    return null;
  }

  // Date validation (for date strings)
  static String? validateDate(String? date, {String fieldName = 'Date'}) {
    if (date == null || date.isEmpty) {
      return '$fieldName is required';
    }
    
    try {
      DateTime.parse(date);
      return null;
    } catch (e) {
      return 'Please enter a valid $fieldName';
    }
  }

  // Future date validation
  static String? validateFutureDate(String? date, {String fieldName = 'Date'}) {
    final dateError = validateDate(date, fieldName: fieldName);
    if (dateError != null) return dateError;
    
    final parsedDate = DateTime.parse(date!);
    if (parsedDate.isBefore(DateTime.now())) {
      return '$fieldName must be in the future';
    }
    
    return null;
  }

  // Past date validation
  static String? validatePastDate(String? date, {String fieldName = 'Date'}) {
    final dateError = validateDate(date, fieldName: fieldName);
    if (dateError != null) return dateError;
    
    final parsedDate = DateTime.parse(date!);
    if (parsedDate.isAfter(DateTime.now())) {
      return '$fieldName must be in the past';
    }
    
    return null;
  }

  // File size validation
  static String? validateFileSize(int? fileSizeBytes, {int? maxSizeBytes}) {
    if (fileSizeBytes == null) {
      return 'File size is required';
    }
    
    final maxSize = maxSizeBytes ?? AppConstants.maxFileSize;
    if (fileSizeBytes > maxSize) {
      return 'File size must be less than ${AppConstants.formatFileSize(maxSize)}';
    }
    
    return null;
  }

  // File extension validation
  static String? validateFileExtension(String? fileName, List<String> allowedExtensions) {
    if (fileName == null || fileName.isEmpty) {
      return 'File name is required';
    }
    
    final extension = fileName.split('.').last.toLowerCase();
    if (!allowedExtensions.contains(extension)) {
      return 'Only ${allowedExtensions.join(', ')} files are allowed';
    }
    
    return null;
  }

  // Image file validation
  static String? validateImageFile(String? fileName) {
    return validateFileExtension(fileName, AppConstants.allowedImageTypes);
  }

  // Document file validation
  static String? validateDocumentFile(String? fileName) {
    return validateFileExtension(fileName, AppConstants.allowedFileTypes);
  }

  // Multiple validation
  static String? validateMultiple(String? value, List<String? Function(String?)> validators) {
    for (final validator in validators) {
      final error = validator(value);
      if (error != null) return error;
    }
    return null;
  }

  // Custom validation with condition
  static String? validateConditional(
    String? value,
    bool condition,
    String? Function(String?) validator,
  ) {
    if (condition) {
      return validator(value);
    }
    return null;
  }

  // Password strength validation
  static PasswordStrength getPasswordStrength(String password) {
    int score = 0;
    
    // Length check
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    
    // Character type checks
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;
    
    // Return strength based on score
    if (score < 2) return PasswordStrength.weak;
    if (score < 4) return PasswordStrength.fair;
    if (score < 5) return PasswordStrength.good;
    return PasswordStrength.strong;
  }

  // Validate password strength
  static String? validatePasswordStrength(String? password, {PasswordStrength minimumStrength = PasswordStrength.fair}) {
    if (password == null || password.isEmpty) {
      return AppConstants.passwordRequiredMessage;
    }
    
    final strength = getPasswordStrength(password);
    final strengthIndex = PasswordStrength.values.indexOf(strength);
    final minimumIndex = PasswordStrength.values.indexOf(minimumStrength);
    
    if (strengthIndex < minimumIndex) {
      return 'Password is too weak. Please use a stronger password.';
    }
    
    return null;
  }
}

// Password strength enum
enum PasswordStrength {
  weak,
  fair,
  good,
  strong,
}

// Extension for password strength
extension PasswordStrengthExtension on PasswordStrength {
  String get name {
    switch (this) {
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.fair:
        return 'Fair';
      case PasswordStrength.good:
        return 'Good';
      case PasswordStrength.strong:
        return 'Strong';
    }
  }
  
  String get description {
    switch (this) {
      case PasswordStrength.weak:
        return 'Add more characters, numbers, and symbols';
      case PasswordStrength.fair:
        return 'Add uppercase letters and symbols';
      case PasswordStrength.good:
        return 'Good password strength';
      case PasswordStrength.strong:
        return 'Excellent password strength';
    }
  }
}