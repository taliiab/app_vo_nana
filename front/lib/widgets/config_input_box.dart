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
    return Container(
      width: 110,
      decoration: BoxDecoration(
        color: const Color(0xFF75A97D).withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.end,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        onChanged: onChanged,
        decoration: const InputDecoration(
          prefixText: "R\$ ",
          prefixStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        ),
      ),
    );
  }
}