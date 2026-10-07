import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PinField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const PinField({
    super.key,
    required this.controller,
    required this.label,
    this.autofocus = false,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      obscureText: true,
      keyboardType: TextInputType.number,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      maxLength: 4,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 24, letterSpacing: 12),
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        border: const OutlineInputBorder(),
      ),
    );
  }
}
