import 'package:flutter/material.dart';
import '../utils/nutrition_standards.dart';
import '../utils/nutrient_utils.dart';
import '../theme/app_theme.dart';

class NutrientGauge extends StatelessWidget {
  final String label;
  final double currentValue;
  final int mealsPerDay;
  final bool isDailyTotal;

  NutrientGauge({
    required this.label,
    required this.currentValue,
    required this.mealsPerDay,
    required this.isDailyTotal,
  });

  @override
  Widget build(BuildContext context) {
    final String normLabel = _normalizeNutrient(label);
    final double maxValue = averageDailyRequirements[normLabel] ?? 100;
    final double percentage = ((currentValue / maxValue) * 100).clamp(0.0, 999.9);

    // 섭취량 상태 결정
    NutrientStatus status = _getNutrientStatus(percentage);

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // 영양소 아이콘
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              _getNutrientIcon(label),
              color: status.color,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          // 영양소 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      formatNutrientValue(label, currentValue),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: status.color,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  status.message,
                  style: TextStyle(
                    fontSize: 14,
                    color: status.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _normalizeNutrient(String nutrient) {
    return nutrient.split('(').first.trim();
  }

  IconData _getNutrientIcon(String nutrient) {
    final normalized = _normalizeNutrient(nutrient).toLowerCase();

    switch (normalized) {
      case "단백질":
        return Icons.egg_alt;
      case "탄수화물":
        return Icons.breakfast_dining;
      case "지방":
        return Icons.oil_barrel;
      case "비타민":
        return Icons.local_florist;
      case "칼슘":
        return Icons.fitness_center;
      case "에너지":
        return Icons.local_fire_department;
      default:
        return Icons.scatter_plot;
    }
  }

  NutrientStatus _getNutrientStatus(double percentage) {
    if (percentage < 30) {
      return NutrientStatus(
        color: Colors.orange,
        message: "섭취량이 부족해요",
      );
    } else if (percentage < 80) {
      return NutrientStatus(
        color: AppTheme.primaryColor,
        message: "적절히 섭취하고 있어요",
      );
    } else if (percentage <= 110) {
      return NutrientStatus(
        color: Colors.green,
        message: "권장량에 가깝게 섭취했어요",
      );
    } else {
      return NutrientStatus(
        color: Colors.red,
        message: "과다 섭취했어요",
      );
    }
  }
}

class NutrientStatus {
  final Color color;
  final String message;

  NutrientStatus({
    required this.color,
    required this.message,
  });
}
