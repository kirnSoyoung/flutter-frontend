import 'package:flutter/material.dart';
import '../utils/nutrient_utils.dart';
import '../utils/nutrition_standards.dart';

class NutrientDetailPopup extends StatelessWidget {
  final String groupName;
  final Map<String, double> intakeMap;

  const NutrientDetailPopup({
    super.key,
    required this.groupName,
    required this.intakeMap,
  });

  @override
  Widget build(BuildContext context) {
    final groupItems = nutrientGroups[groupName] ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$groupName 상세",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...groupItems.map((nutrient) {
            final value = intakeMap[nutrient] ?? 0;
            final unit = getNutrientUnit(nutrient) ?? "";
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(nutrient),
                  Text(formatNutrientValue(nutrient, value)),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
