import 'package:flutter/material.dart';
import '../utils/formatters.dart';

class HomeTerm extends StatelessWidget {
  final String label;
  final double? value;
  final bool highlight;

  const HomeTerm({
    super.key,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
          const SizedBox(height: 4),
          Text(
            value == null ? '—' : formatNumber(value!),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: highlight ? 17 : 15,
            ),
          ),
        ],
      ),
    );
  }
}