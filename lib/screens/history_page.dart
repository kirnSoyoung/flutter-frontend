import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../screens/recognition_page.dart';
import '../screens/result_page.dart';
import '../utils/data_manager.dart';
import '../utils/nutrient_utils.dart';
import '../utils/shared_prefs.dart';
import '../utils/nutrition_standards.dart';
import '../models/meal_model.dart';

class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  DateTime _currentWeekStart = DateTime.now();
  DateTime? _selectedDate;
  Map<String, double>? _rdi;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ko_KR');
    _currentWeekStart = _getWeekStart(DateTime.now());
    _selectedDate = DateTime.now();
    _loadRdi();
  }

  Future<void> _loadRdi() async {
    final user = await SharedPrefs.getLoggedInUser();
    if (user != null) {
      final rdi = calculatePersonalRequirements(user);
      setState(() => _rdi = rdi);
    }
  }

  DateTime _getWeekStart(DateTime date) {
    int wd = date.weekday % 7;
    return date.subtract(Duration(days: wd));
  }

  void _nextWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(Duration(days: 7));
      _selectedDate = _currentWeekStart;
    });
  }

  void _previousWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.subtract(Duration(days: 7));
      _selectedDate = _currentWeekStart;
    });
  }

  void _selectDate(DateTime date) => setState(() => _selectedDate = date);

  Map<String, double> calculateIntake(List<Meal> meals) {
    final result = <String, double>{};
    if (_rdi == null) return result;
    for (var k in _rdi!.keys) result[k] = 0.0;
    for (var meal in meals) {
      meal.nutrients.forEach((_, nutMap) {
        nutMap.forEach((k, v) {
          final norm = normalizeNutrientKey(k);
          if (result.containsKey(norm)) result[norm] = result[norm]! + v;
        });
      });
    }
    return result;
  }

  double calculateGroupPercent(Map<String, double> intake, List<String> keys) {
    if (_rdi == null) return 0.0;
    final filt = keys.where((k) => intake.containsKey(k)).toList();
    if (filt.isEmpty) return 0.0;
    final sum = filt.map((k) {
      final goal = _rdi![k] ?? 1.0;
      return (intake[k]! / goal).clamp(0.0, 1.0);
    }).reduce((a, b) => a + b);
    return (sum / filt.length).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);
    final weekDays = List.generate(7, (i) => _currentWeekStart.add(Duration(days: i)));
    final meals = dataManager.getMealsForDate(_selectedDate!) ?? [];
    final dailyIntake = calculateIntake(meals);

    if (_rdi == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
          if (picked != null) {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => RecognitionPage(
                image: File(picked.path),
                selectedDate: _selectedDate,
              ),
            ));
          }
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: Icon(Icons.photo_library, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(icon: Icon(Icons.arrow_back), onPressed: _previousWeek),
                    Text(
                      DateFormat.yMMMM('ko_KR').format(_selectedDate!),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(icon: Icon(Icons.arrow_forward), onPressed: _nextWeek),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: weekDays.map((date) {
                    final sel = _selectedDate;
                    final isSel = sel?.day == date.day && sel?.month == date.month;
                    final has = (dataManager.getMealsForDate(date)?.isNotEmpty ?? false);
                    final same = date.month == sel?.month;
                    return GestureDetector(
                      onTap: () => _selectDate(date),
                      child: Column(
                        children: [
                          Text(
                            DateFormat.E('ko_KR').format(date),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: same ? Colors.black : Colors.grey,
                            ),
                          ),
                          SizedBox(height: 4),
                          Container(
                            width: 36, height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSel ? Colors.green : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${date.day}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                color: isSel ? Colors.white : (same ? Colors.black : Colors.grey),
                              ),
                            ),
                          ),
                          SizedBox(height: 4),
                          Container(
                            width: 6, height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: has ? Colors.green : Colors.transparent,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 16),
              children: [
                if (meals.isNotEmpty)
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    margin: EdgeInsets.only(bottom: 12),
                    elevation: 3,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("평균 섭취량", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 6),
                          ..._buildGroupSummary(dailyIntake, dense: true),
                        ],
                      ),
                    ),
                  ),

                GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: meals.length,
                  itemBuilder: (ctx, idx) {
                    final m = meals[idx];
                    final intake = calculateIntake([m]);
                    final title = m.mealNames.isNotEmpty ? m.mealNames.first : "식사";
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NutritionResultPage(
                              imagePath: m.image.path,
                              nutrients: m.nutrients,
                              selectedDate: _selectedDate!,
                              mealNames: m.mealNames,
                              servingsMap: m.servings,
                              isFromHistory: true,
                              sourceMeal: m,
                            ),
                          ),
                        );
                      },
                      child: Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                        margin: EdgeInsets.zero,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                              child: Image.file(
                                File(m.image.path),
                                height: 70,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(12, 4, 12, 0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                  SizedBox(height: 1),
                                  ..._buildGroupSummary(intake, dense: true),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildGroupSummary(Map<String, double> intake, {bool dense = false}) {
    final groups = {
      '에너지': ['에너지'],
      '탄수화물': ['탄수화물', '식이섬유'],
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
    final entries = groups.entries.toList();
    return List.generate(entries.length, (i) {
      final label = entries[i].key;
      final pct = calculateGroupPercent(intake, entries[i].value);
      return Padding(
        padding: EdgeInsets.only(bottom: i == entries.length - 1 ? 0 : (dense ? 2 : 6)),
        child: Row(
          children: [
            SizedBox(width: dense ? 70 : 100, child: Text(label, style: TextStyle(fontSize: dense ? 13 : 14))),
            Expanded(
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: Colors.grey[200],
                color: Colors.green,
                minHeight: dense ? 4 : 6,
              ),
            ),
            SizedBox(width: 4),
            Text("${(pct * 100).toStringAsFixed(0)}%", style: TextStyle(fontSize: dense ? 12 : 14)),
          ],
        ),
      );
    });
  }
}
