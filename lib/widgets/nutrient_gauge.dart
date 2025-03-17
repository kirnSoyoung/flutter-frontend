import 'package:flutter/material.dart';
import '../utils/nutrition_standards.dart'; // 하루 권장 영양소 데이터 가져오기

/// 영양소 섭취량을 시각적으로 표시하는 게이지 위젯
class NutrientGauge extends StatelessWidget {
  final String label; // 영양소 이름 (예: 탄수화물, 단백질)
  final double currentValue; // 현재 섭취량 (한 끼 또는 하루 누적)
  final int mealsPerDay; // 하루 식사 횟수
  final bool isDailyTotal; // 하루 총 섭취량인지 여부

  NutrientGauge({
    required this.label,
    required this.currentValue,
    required this.mealsPerDay,
    required this.isDailyTotal,
  });

  @override
  Widget build(BuildContext context) {
    // 하루 평균 권장 섭취량 가져오기 (기본값 100)
    double dailyRequirement = averageDailyRequirements[label] ?? 100;

    // 섭취량 퍼센트 계산 (하루 누적 또는 한 끼 기준)
    double percentage = isDailyTotal
        ? (currentValue / dailyRequirement * 100).clamp(0.0, 150) // 하루 기준
        : (currentValue / (dailyRequirement / mealsPerDay) * 100).clamp(0.0, 150); // 한 끼 기준

    // 게이지 길이 계산 (화면 너비 기반)
    double gaugeWidth = (percentage / 100).clamp(0.0, 1.5) * MediaQuery.of(context).size.width;

    // 영양소 단위 설정
    String unit;
    if (["비타민 A", "비타민 D", "비타민 K", "비타민 B12", "엽산"].contains(label)) {
      unit = "μg";
    } else if ([
      "비타민 B1", "비타민 B2", "비타민 B3", "비타민 B6", "비타민 C", "비타민 E",
      "철분", "마그네슘", "아연", "인"
    ].contains(label)) {
      unit = "mg";
    } else if (["오메가-3"].contains(label)) {
      unit = "g";
    } else {
      unit = "g";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$label: ${currentValue.toStringAsFixed(1)} $unit (${percentage.toStringAsFixed(1)}%)",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Stack(
          children: [
            // 배경 바 (전체 게이지)
            Container(
              width: double.infinity,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            // 실제 섭취량 게이지 바
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
