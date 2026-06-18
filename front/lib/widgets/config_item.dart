import 'package:flutter/material.dart';

class ConfigItem extends StatelessWidget {
  final String label;
  final Widget trailing;

  const ConfigItem({
    super.key,
    required this.label,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF27422C),
              ),
            ),
          ),
          const SizedBox(width: 24),
          Align(
            alignment: Alignment.centerRight,
            child: trailing,
          ),
        ],
      ),
    );
  }
}