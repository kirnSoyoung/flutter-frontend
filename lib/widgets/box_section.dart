import 'package:flutter/material.dart';
import '../utils/nutrition_standards.dart';
import '../utils/nutrient_utils.dart';
import '../widgets/nutrient_gauge.dart';
import '../widgets/nutrient_box.dart';

class GroupedNutrientSection extends StatefulWidget {
  final Map<String, double> intakeMap;

  const GroupedNutrientSection({super.key, required this.intakeMap});

  @override
  State<GroupedNutrientSection> createState() => _GroupedNutrientSectionState();
}

class _GroupedNutrientSectionState extends State<GroupedNutrientSection> {
  final _scrollKey = GlobalKey();
  String? selectedGroup;

  void _onGroupTap(String group) {
    setState(() {
      selectedGroup = selectedGroup == group ? null : group;
    });

    // ✅ 직접 실행
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _scrollKey.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final groupPercents = calculateGroupPercents(widget.intakeMap, averageDailyRequirements);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Center(
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: groupPercents.entries.map((entry) {
              return GroupedNutrientBox(
                groupName: entry.key,
                percent: entry.value,
                isSelected: selectedGroup == entry.key,
                onTap: () => _onGroupTap(entry.key),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        if (selectedGroup != null)
          Container(
            key: _scrollKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 32),
                Text(
                  "$selectedGroup 섭취 상세",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...nutrientGroups[selectedGroup]!.map((nutrient) {
                  final value = widget.intakeMap[nutrient] ?? 0.0;
                  return NutrientGauge(
                    label: nutrient,
                    currentValue: value,
                    mealsPerDay: 3,
                    isDailyTotal: false,
                  );
                }).toList(),
              ],
            ),
          ),
      ],
    );
  }
}