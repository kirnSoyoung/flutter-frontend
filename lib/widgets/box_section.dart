import 'package:flutter/material.dart';
import '../utils/nutrition_standards.dart';
import '../utils/nutrient_utils.dart';
import '../utils/shared_prefs.dart';
import '../widgets/nutrient_gauge.dart';
import '../widgets/nutrient_box.dart';

class GroupedNutrientSection extends StatefulWidget {
  final Map<String, double> intakeMap;
  final int daySpan;

  const GroupedNutrientSection({super.key, required this.intakeMap, this.daySpan = 1});

  @override
  State<GroupedNutrientSection> createState() => _GroupedNutrientSectionState();
}

class _GroupedNutrientSectionState extends State<GroupedNutrientSection> {
  final _scrollKey = GlobalKey();
  String? selectedGroup;
  Map<String, double>? customRequirements;

  void _onGroupTap(String group) {
    setState(() {
      selectedGroup = selectedGroup == group ? null : group;
    });

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
  void initState() {
    super.initState();
    _loadUserRequirements();
  }

  Future<void> _loadUserRequirements() async {
    final user = await SharedPrefs.getLoggedInUser();
    if (user != null) {
      setState(() {
        customRequirements = calculatePersonalRequirements(user);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (customRequirements == null) {
      return Center(child: CircularProgressIndicator());
    }

    final adjustedRequirements = {
      for (final entry in customRequirements!.entries)
        entry.key: entry.value * widget.daySpan
    };
    final groupPercents = calculateGroupPercents(widget.intakeMap, adjustedRequirements);

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
                  final max = customRequirements?[nutrient] ?? 100.0;
                  return NutrientGauge(
                    label: nutrient,
                    currentValue: value,
                    maxValue: max,
                    mealsPerDay: 3,
                    isDailyTotal: false,
                    daySpan: widget.daySpan,
                  );
                }).toList(),
              ],
            ),
          ),
      ],
    );
  }
}
