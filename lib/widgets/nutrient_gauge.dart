import 'package:flutter/material.dart';

import '../utils/nutrition_standards.dart';
import '../utils/nutrient_utils.dart';

class NutrientGauge extends StatelessWidget {
  final String label; // 영양소 이름 (예: 탄수화물, 단백질)
  final double currentValue;
  final int mealsPerDay;
  final bool isDailyTotal; // 하루 총 섭취량인지 여부

  NutrientGauge({
    required this.label,
    required this.currentValue,
    required this.mealsPerDay,
    required this.isDailyTotal,
  });

  @override
  Widget build(BuildContext context) {
    double dailyRequirement = averageDailyRequirements[label] ?? 100;

    // 섭취량 퍼센트 계산 (하루 누적 또는 한 끼 기준)
    double percentage = isDailyTotal
        ? (currentValue / dailyRequirement * 100).clamp(0.0, 150) // 하루 기준
        : (currentValue / (dailyRequirement / mealsPerDay) * 100).clamp(0.0, 150); // 한 끼 기준

    double gaugeWidth = (percentage / 100).clamp(0.0, 1.5) * MediaQuery.of(context).size.width;
    String unit = getNutrientUnit(label);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$label: ${currentValue.toStringAsFixed(1)} $unit (${percentage.toStringAsFixed(1)}%)",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Stack(
          children: [
            Container(
              width: double.infinity,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            Container(
              width: gaugeWidth,
              height: 20,
              decoration: BoxDecoration(
                color: percentage > 100 ? Colors.red : Colors.green, // 초과 섭취 시 빨강
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
      ],
    );
  }
}
