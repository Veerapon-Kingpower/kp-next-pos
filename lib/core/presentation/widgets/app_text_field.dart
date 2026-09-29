import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../test_ids.dart';
import 'test_id.dart';

/// Shared form field — labelled text input with an inline error message,
/// used by every form workflow (customer, registration, settings,
/// discount/promotion entry, ...). With an [id] it gets a clear (✕) button
/// while it holds text.
class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;

  /// Automation id for the field; also turns on the clear button
  /// (`FieldIds.clear(id)`).
  final String? id;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.id,
  });

  @override
  Widget build(BuildContext context) {
    final field = ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) => TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        onChanged: onChanged,
        inputFormatters: inputFormatters,
        textCapitalization: textCapitalization,
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          border: const OutlineInputBorder(),
          suffixIcon: id == null || value.text.isEmpty
              ? null
              : ClearFieldButton(
                  id: FieldIds.clear(id!),
                  controller: controller,
                  onCleared: onChanged,
                ),
        ),
      ),
    );
    return id == null ? field : TestId(id!, child: field);
  }
}

/// The ✕ that empties a text field; reports the change through
/// [onCleared] so the owner reacts as it would to typing.
class ClearFieldButton extends StatelessWidget {
  final String id;
  final TextEditingController controller;
  final ValueChanged<String>? onCleared;

  const ClearFieldButton({
    super.key,
    required this.id,
    required this.controller,
    this.onCleared,
  });

  @override
  Widget build(BuildContext context) {
    return TestId(
      id,
      child: IconButton(
        tooltip: 'Clear',
        icon: const Icon(Icons.cancel, size: 18),
        color: const Color(0xFF9AA2AE),
        onPressed: () {
          controller.clear();
          onCleared?.call('');
        },
      ),
    );
  }
}
