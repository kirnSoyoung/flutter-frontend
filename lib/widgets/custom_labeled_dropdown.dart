import 'package:flutter/material.dart';

class CustomLabeledDropdown extends StatelessWidget {
  final String label;
  final String value;
  final Map<String, String> items;
  final void Function(String?) onChanged;

  const CustomLabeledDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 5),
        DropdownButton<String>(
          value: value,
          isExpanded: true,
          onChanged: onChanged,
          items: items.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.value),
            );
          }).toList(),
        ),
      ],
    );
  }
}
