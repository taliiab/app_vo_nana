import 'package:flutter/material.dart';

class ConfigInputBox extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const ConfigInputBox({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 105,
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.end,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
        onChanged: onChanged,
        decoration: InputDecoration(
          prefixText: "R\$ ",
          prefixStyle: const TextStyle(
            color: Color(0xFF3B5E41),
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
          filled: true,
          fillColor: const Color(0xFFF0F4F1),
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.12)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF75A97D), width: 1.5),
          ),
        ),
      ),
    );
  }
}