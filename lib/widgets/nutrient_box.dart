import 'package:flutter/material.dart';

class GroupedNutrientBox extends StatelessWidget {
  final String groupName;
  final double percent;
  final bool isSelected;
  final VoidCallback onTap;

  const GroupedNutrientBox({
    required this.groupName,
    required this.percent,
    required this.onTap,
    this.isSelected = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 100,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: Text(
                groupName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _BorderFillPainter(percent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BorderFillPainter extends CustomPainter {
  final double percent;

  _BorderFillPainter(this.percent);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = percent > 1.0 ? Colors.red : Colors.green
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final path = Path();
    final perimeter = (size.width + size.height) * 2;
    final fillLength = perimeter * percent.clamp(0.0, 2.0);

    double drawn = 0.0;
    Offset current = Offset(0, 0);

    void drawLine(Offset to) {
      final segment = (to - current).distance;
      if (drawn + segment > fillLength) {
        final ratio = (fillLength - drawn) / segment;
        final limitedEnd = Offset.lerp(current, to, ratio)!;
        path.moveTo(current.dx, current.dy);
        path.lineTo(limitedEnd.dx, limitedEnd.dy);
        drawn = fillLength;
      } else {
        path.moveTo(current.dx, current.dy);
        path.lineTo(to.dx, to.dy);
        drawn += segment;
        current = to;
      }
    }

    drawLine(Offset(size.width, 0));
    drawLine(Offset(size.width, size.height));
    drawLine(Offset(0, size.height));
    drawLine(Offset(0, 0));

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
