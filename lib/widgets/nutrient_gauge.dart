import 'package:flutter/material.dart';

class NutrientProgressCircle extends StatelessWidget {
  final double intake;
  final double rdi;
  final String label;

  const NutrientProgressCircle({
    required this.intake,
    required this.rdi,
    required this.label,
    super.key,
  });


  @override
  Widget build(BuildContext context) {
    final progress = (intake / rdi);
    final percent = (progress * 100).round();
    final color = progress > 1.0
        ? Colors.red
        : (progress >= 1.0 ? Colors.red : Colors.blueAccent);

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
                value: progress,
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
