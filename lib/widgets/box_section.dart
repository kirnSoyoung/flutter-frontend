import 'package:flutter/material.dart';
import '../utils/shared_prefs.dart';
import '../utils/nutrition_standards.dart';
import '../models/user_model.dart';
import 'nutrient_gauge.dart';

class GroupedNutrientSection extends StatefulWidget {
  final Map<String, double> intakeMap;
  final int? daySpan; // 일수 기준으로 정규화할 경우 사용

  const GroupedNutrientSection({
    Key? key,
    required this.intakeMap,
    this.daySpan,
  }) : super(key: key);

  @override
  State<GroupedNutrientSection> createState() => _GroupedNutrientSectionState();
}

class _GroupedNutrientSectionState extends State<GroupedNutrientSection> {
  Map<String, double>? _rdi;

  static const _groups = <String, List<String>>{
    '에너지': ['에너지'],
    '탄수화물/식이섬유': ['탄수화물', '식이섬유'],
    '단백질/지방': ['단백질', '지방'],
    '비타민': [
      '비타민A','비타민B1','비타민B2','비타민B6','비타민B12',
      '비타민C','비타민D','비타민E','비타민K',
      '엽산','나이아신','판토텐산','비오틴'
    ],
    '미네랄': [
      '칼슘','마그네슘','철','아연','구리','망간',
      '요오드','셀레늄','인','나트륨','칼륨'
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadRdi();
  }

  Future<void> _loadRdi() async {
    final user = await SharedPrefs.getLoggedInUser();
    if (user != null) {
      final personal = calculatePersonalRequirements(user);
      setState(() => _rdi = personal);
    }
  }

  double _calculateProgress(String groupLabel) {
    if (_rdi == null) return 0.0;
    final keys = _groups[groupLabel]!;
    double sum = 0;
    final divisor = widget.daySpan ?? 1;

    for (var k in keys) {
      final goal = (_rdi![k] ?? 0) * divisor;
      final got = widget.intakeMap[k] ?? 0;
      if (goal > 0) sum += (got / goal); // clamp 제거 → 초과 표시 가능
    }
    return keys.isEmpty ? 0 : sum / keys.length;
  }

  @override
  Widget build(BuildContext context) {
    if (_rdi == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final labels = _groups.keys.toList();
    final firstRow = labels.sublist(0, 3);
    final secondRow = labels.sublist(3);

    Widget _buildCircle(String label) {
      return NutrientProgressCircle(
        progress: _calculateProgress(label),
        label: label,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: firstRow.map((lbl) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _buildCircle(lbl),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: secondRow.map((lbl) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _buildCircle(lbl),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}