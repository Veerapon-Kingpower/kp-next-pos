import 'package:flutter/material.dart';

/// Shared form field — labelled text input with an inline error message,
/// used by every form workflow (customer, registration, settings,
/// discount/promotion entry, ...).
class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
