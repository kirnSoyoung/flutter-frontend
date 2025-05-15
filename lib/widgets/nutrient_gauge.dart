import 'package:flutter/material.dart';

class NutrientProgressCircle extends StatelessWidget {
  final double progress; // ex: 1.25 → 125%
  final String label;

  const NutrientProgressCircle({
    super.key,
    required this.progress,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();
    final color = progress > 1.0
        ? Colors.red
        : (progress >= 1.0 ? Colors.green : Colors.blueAccent);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                value: progress.clamp(0.0, 1.0), // 게이지는 100%까지만
                strokeWidth: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Text(
              "$percent%",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}
