// lib/widgets/custom_text_field.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String labelText;
  final String? hintText;
  final IconData? icon;
  final TextInputType? keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;
  final FormFieldValidator<String>? validator;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;

  const CustomTextField({
    super.key,
    this.controller,
    required this.labelText,
    this.hintText,
    this.icon,
    this.keyboardType,
    this.readOnly = false,
    this.onTap,
    this.validator,
    this.inputFormatters,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      validator: validator,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        isDense: true,
        suffixIcon: icon != null ? Icon(icon) : null,
        fillColor: Colors.white,
        filled: true,
      ),
    );
  }
}