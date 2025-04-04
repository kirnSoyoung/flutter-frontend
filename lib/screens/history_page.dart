import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../screens/diet_recognition_page.dart';
import '../screens/nutrition_result_page.dart';
import '../utils/data_manager.dart';
import '../utils/nutrition_standards.dart';
import '../utils/nutrient_utils.dart';
import '../widgets/nutrient_gauge.dart';
import '../models/meal_model.dart';

class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  DateTime _currentWeekStart = DateTime.now();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ko_KR');
    _currentWeekStart = _getWeekStart(DateTime.now());
    _selectedDate = DateTime.now();
  }

  DateTime _getWeekStart(DateTime date) {
    int weekday = date.weekday;
    return date.subtract(Duration(days: weekday % 7));
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

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  Map<String, double> calculateDailyIntake(List meals) {
    final intake = <String, double>{};
    for (var key in averageDailyRequirements.keys) {
      intake[key] = 0.0;
    }

    for (var meal in meals) {
      meal.nutrients.forEach((food, nutrientMap) {
        nutrientMap.forEach((key, value) {
          final normalized = normalizeNutrientKey(key);
          if (intake.containsKey(normalized)) {
            intake[normalized] = intake[normalized]! + value;
          }
        });
      });
    }
    return intake;
  }

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);
    List<DateTime> weekDays = List.generate(
        7, (index) => _currentWeekStart.add(Duration(days: index)));
    final meals = dataManager.getMealsForDate(_selectedDate!) ?? [];
    final dailyIntake = calculateDailyIntake(meals);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
          if (pickedFile != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DietRecognitionPage(
                  image: File(pickedFile.path),
                  selectedDate: _selectedDate,
                ),
              ),
            );
          }
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add_a_photo, color: Colors.white),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                        icon: Icon(Icons.arrow_back), onPressed: _previousWeek),
                    Text(
                      DateFormat.yMMMM('ko_KR').format(_selectedDate!),
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                        icon: Icon(Icons.arrow_forward), onPressed: _nextWeek),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: weekDays.map((date) {
                    final isSelected = _selectedDate?.day == date.day && _selectedDate?.month == date.month;
                    final hasMeal = (dataManager.getMealsForDate(date)?.isNotEmpty ?? false);
                    final weekdayLabel = DateFormat.E('ko_KR').format(date);
                    final isSameMonth = date.month == _selectedDate?.month;

                    return GestureDetector(
                      onTap: () => _selectDate(date),
                      child: Column(
                        children: [
                          Text(
                            weekdayLabel,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSameMonth ? Colors.black : Colors.grey,
                            ),
                          ),
                          SizedBox(height: 4),
                          Container(
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.green : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${date.day}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected
                                    ? Colors.white
                                    : isSameMonth
                                    ? Colors.black
                                    : Colors.grey,
                              ),
                            ),
                          ),
                          SizedBox(height: 4),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: hasMeal ? Colors.green : Colors.transparent,
                            ),
                          )
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 100,
                    child: meals.isNotEmpty
                        ? ListView(
                      scrollDirection: Axis.horizontal,
                      children: meals.map((meal) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NutritionResultPage(
                                  imagePath: meal.image.path,
                                  nutrients: meal.nutrients,
                                  selectedDate: _selectedDate!,
                                  mealNames: meal.mealNames,
                                  isFromHistory: true,
                                  sourceMeal: meal, // ✅ 추가됨
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: EdgeInsets.only(right: 10),
                            child: Image.file(
                              File(meal.image.path),
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      }).toList(),
                    )
                        : Center(child: Text("등록된 식단이 없습니다.")),
                  ),
                  const SizedBox(height: 20),
                  if (meals.isNotEmpty) ...[
                    Text(
                      DateFormat('MM월 dd일의 영양소 섭취량', 'ko_KR')
                          .format(_selectedDate!),
                      style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children:
                        averageDailyRequirements.entries.map((entry) {
                          final label = entry.key;
                          final current = dailyIntake[label] ?? 0.0;
                          return NutrientGauge(
                            label: label,
                            currentValue: current,
                            mealsPerDay: 3,
                            isDailyTotal: true,
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}