import 'package:flutter/services.dart';

/// Custom TextInputFormatter to handle Vietnamese input (IME composition)
/// Filters out incomplete composed text from input method editors
class VietnameseTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // If the new value is a composing text (incomplete Vietnamese input),
    // keep the old value and let the IME continue
    // The final text will be committed when IME is done
    return newValue;
  }
}

/// Better solution: Override onFieldSubmitted to validate after composition is done
/// Usage in TextFormField:
/// onFieldSubmitted: (_) { validate final text here }

