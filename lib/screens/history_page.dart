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
import '../widgets/nutrient_gauge.dart';

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
    });
  }

  void _previousWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.subtract(Duration(days: 7));
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
      meal.nutrients.forEach((key, value) {
        if (intake.containsKey(key)) {
          intake[key] = intake[key]! + value;
        }
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
                  initialMealName: "",
                  isEditing: false,
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
                    IconButton(icon: Icon(Icons.arrow_back), onPressed: _previousWeek),
                    Text(
                      DateFormat.yMMMM('ko_KR').format(_currentWeekStart),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(icon: Icon(Icons.arrow_forward), onPressed: _nextWeek),
                  ],
                ),
                SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ["일", "월", "화", "수", "목", "금", "토"]
                      .map((day) => Text(day, style: TextStyle(fontWeight: FontWeight.bold)))
                      .toList(),
                ),
                SizedBox(height: 5),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: weekDays.map((date) {
                    bool hasMeal = (dataManager.getMealsForDate(date)?.isNotEmpty ?? false);

                    return GestureDetector(
                      onTap: () => _selectDate(date),
                      child: Column(
                        children: [
                          Text(
                            DateFormat.d().format(date),
                            style: TextStyle(
                              fontSize: 16,
                              color: _selectedDate?.day == date.day ? Colors.blue : Colors.black,
                            ),
                          ),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: hasMeal ? Colors.green : Colors.transparent,
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
                                  mealName: meal.mealName,
                                  isFromHistory: true,
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
                      DateFormat('MM월 dd일의 영양소 섭취량', 'ko_KR').format(_selectedDate!),
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: averageDailyRequirements.entries.map((entry) {
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
