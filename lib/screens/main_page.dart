import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models/meal_model.dart';
import '../utils/data_manager.dart';
import '../utils/nutrition_standards.dart';
import '../widgets/nutrient_gauge.dart';
import '../theme/app_theme.dart';
import 'diet_recognition_page.dart';
import 'nutrition_result_page.dart';

class HomePage extends StatefulWidget {
  final String email;
  HomePage(this.email);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String selectedPeriod = 'day'; // 'day', 'week', 'month'
  final int mealsPerDay = 3;

  void setImage(File image) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DietRecognitionPage(image: image),
      ),
    ).then((_) {
      setState(() {});
    });
  }

  List<Meal> getMealsInRange(Map<DateTime, List<Meal>> allMeals, DateTime start, DateTime end) {
    return allMeals.entries
        .where((entry) => entry.key.isAfter(start.subtract(Duration(days: 1))) && entry.key.isBefore(end.add(Duration(days: 1))))
        .expand((entry) => entry.value)
        .toList();
  }

  Map<String, double> sumNutrients(List<Meal> meals) {
    Map<String, double> total = {
      for (var key in averageDailyRequirements.keys) key: 0.0
    };
    for (var meal in meals) {
      meal.nutrients.forEach((key, value) {
        if (total.containsKey(key)) {
          total[key] = total[key]! + value;
        }
      });
    }
    return total;
  }

  String getPeriodLabel() {
    switch (selectedPeriod) {
      case 'day': return '오늘의';
      case 'week': return '일주일간';
      case 'month': return '한달간';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<DataManager>(
        builder: (context, dataManager, child) {
          DateTime today = DateTime.now();
          DateTime start, end;

          if (selectedPeriod == 'day') {
            start = end = DateTime(today.year, today.month, today.day);
          } else if (selectedPeriod == 'week') {
            int weekday = today.weekday % 7;
            start = today.subtract(Duration(days: weekday));
            end = start.add(Duration(days: 5));
          } else {
            start = DateTime(today.year, today.month, 1);
            end = DateTime(today.year, today.month + 1, 0);
          }

          List<Meal> meals = getMealsInRange(dataManager.allMeals, start, end);
          Map<String, double> intake = sumNutrients(meals);

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                floating: true,
                pinned: true,
                backgroundColor: Colors.white,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  title: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.restaurant_menu, color: AppTheme.primaryColor, size: 24),
                        SizedBox(width: 8),
                        Text(
                          getPeriodLabel() + " 식단",
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  centerTitle: true,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Text(
                              "오늘 먹은 음식을 기록해보세요",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "사진 한 장으로 간편하게\n영양 정보를 확인할 수 있어요",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                            ),
                            SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildCameraButton(
                                  icon: Icons.camera_alt,
                                  label: "촬영하기",
                                  onTap: () async {
                                    ImagePicker picker = ImagePicker();
                                    final XFile? image = await picker.pickImage(source: ImageSource.camera);
                                    if (image != null) {
                                      setImage(File(image.path));
                                    }
                                  },
                                ),
                                _buildCameraButton(
                                  icon: Icons.photo_library,
                                  label: "갤러리",
                                  onTap: () async {
                                    ImagePicker picker = ImagePicker();
                                    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                                    if (image != null) {
                                      setImage(File(image.path));
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 32),

                      if (meals.isNotEmpty) ...[
                        Text(
                          getPeriodLabel() + " 식사 기록",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 16),
                        Container(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: meals.length,
                            itemBuilder: (context, index) {
                              final meal = meals[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => NutritionResultPage(
                                        imagePath: meal.image.path,
                                        nutrients: meal.nutrients,
                                        selectedDate: today,
                                        mealNames: meal.mealNames,
                                        isFromHistory: true,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 120,
                                  margin: EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    image: DecorationImage(
                                      image: FileImage(meal.image),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: 32),
                      ],

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: ['day', 'week', 'month'].map((period) {
                          String label = period == 'day' ? '하루' : period == 'week' ? '일주일' : '한달';
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: selectedPeriod == period ? AppTheme.primaryColor : Colors.grey[300],
                                foregroundColor: selectedPeriod == period ? Colors.white : Colors.black87,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              onPressed: () {
                                setState(() {
                                  selectedPeriod = period;
                                });
                              },
                              child: Text(label),
                            ),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 16),

                      Text(
                        getPeriodLabel() + " 영양소 섭취량",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!, width: 1),
                        ),
                        child: Column(
                          children: averageDailyRequirements.entries.map((entry) {
                            final label = entry.key;
                            final current = intake[label] ?? 0.0;
                            return NutrientGauge(
                              label: label,
                              currentValue: current,
                              mealsPerDay: mealsPerDay,
                              isDailyTotal: true,
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCameraButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppTheme.primaryColor),
            SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
