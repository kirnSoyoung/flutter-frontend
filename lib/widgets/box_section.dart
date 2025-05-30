import 'package:flutter/material.dart';
import '../utils/shared_prefs.dart';
import '../utils/nutrition_standards.dart';
import '../utils/nutrient_utils.dart';
import 'nutrient_gauge.dart';

class GroupedNutrientSection extends StatefulWidget {
  final Map<String, double> intakeMap;
  final int? daySpan;

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
  String? _selectedGroup;

  static const _groups = <String, List<String>>{
    '에너지': ['에너지'],
    '탄수화물/식이섬유': ['탄수화물', '식이섬유'],
    '단백질': ['단백질'],
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
      setState(() => _rdi = calculatePersonalRequirements(user));
    }
  }

  double _calculateProgress(String groupLabel) {
    if (_rdi == null) return 0.0;
    final keys = _groups[groupLabel]!;
    final divisor = widget.daySpan ?? 1;
    final adjusted = {
      for (final e in _rdi!.entries) e.key: e.value * divisor,
    };
    final useKeys = keys.where((k) => widget.intakeMap.containsKey(k)).toList();
    return calculateGroupPercent(
      intake: widget.intakeMap,
      rdi: adjusted,
      keys: useKeys,
    );
  }

  void _toggleGroup(String label) {
    setState(() {
      _selectedGroup = _selectedGroup == label ? null : label;
    });
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
      final progress = _calculateProgress(label);
      final selected = _selectedGroup == label;

      return GestureDetector(
        onTap: () => _toggleGroup(label),
        child: NutrientProgressCircle(
          intake: progress * 100,
          rdi: 100,
          label: label,
          isSelected: selected,  // ← 선택 여부 전달
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: firstRow
                .map((lbl) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _buildCircle(lbl),
            ))
                .toList(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: secondRow
                .map((lbl) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _buildCircle(lbl),
            ))
                .toList(),
          ),
          if (_selectedGroup != null) ...[
            const SizedBox(height: 12),
            _buildDetailList(_selectedGroup!),
          ]
        ],
      ),
    );
  }

  Widget _buildDetailList(String group) {
    final keys = _groups[group]!;
    final divisor = widget.daySpan ?? 1;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: keys.map((nutrient) {
          final amount = widget.intakeMap[nutrient] ?? 0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(nutrient, style: const TextStyle(fontSize: 14)),
                Text(
                  formatNutrientValue(nutrient, amount / divisor),
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
