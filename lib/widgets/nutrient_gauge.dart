import 'package:flutter/material.dart';

class NutrientProgressCircle extends StatelessWidget {
  final double intake;
  final double rdi;
  final String label;
  final bool isSelected;  // 추가

  const NutrientProgressCircle({
    required this.intake,
    required this.rdi,
    required this.label,
    this.isSelected = false,  // 기본값 false
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final progress = intake / rdi;
    final percent = (progress * 100).round();
    final color = progress > 1.0 ? Colors.red : Colors.blueAccent;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // 선택 시 배경색 + 진한 테두리
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? Colors.blueAccent.withOpacity(0.2)
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected ? Colors.blueAccent : Colors.transparent,
                  width: isSelected ? 4 : 0,
                ),
              ),
            ),
            // 실제 프로그레스 인디케이터
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            // 퍼센트 텍스트
            Text(
              "$percent%",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.blueAccent : Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? Colors.blueAccent : Colors.black87,
          ),
        ),
      ],
    );
  }
}
