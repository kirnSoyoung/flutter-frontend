import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/data_manager.dart';
import '../utils/nutrition_standards.dart';
import '../widgets/image_picker_widget.dart';
import '../widgets/nutrient_gauge.dart';
import '../theme/app_theme.dart';
import 'diet_recognition_page.dart';

class HomePage extends StatefulWidget {
  final String email;
  HomePage(this.email);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<DataManager>(
        builder: (context, dataManager, child) {
          DateTime today = DateTime.now();
          List meals = dataManager.getMealsForDate(today) ?? [];

          Map<String, double> dailyIntake = {
            for (var key in averageDailyRequirements.keys) key: 0.0
          };

          for (var meal in meals) {
            meal.nutrients.forEach((key, value) {
              if (dailyIntake.containsKey(key)) {
                dailyIntake[key] = dailyIntake[key]! + value;
              }
            });
          }

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
                        Icon(
                          Icons.restaurant_menu,
                          color: AppTheme.primaryColor,
                          size: 24,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "오늘의 식단",
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
                      // 메인 카메라 섹션
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
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
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
                                    final XFile? image = await picker.pickImage(
                                      source: ImageSource.camera,
                                    );
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
                                    final XFile? image = await picker.pickImage(
                                      source: ImageSource.gallery,
                                    );
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

                      // 오늘의 식사 기록
                      if (meals.isNotEmpty) ...[
                        Text(
                          "오늘의 식사 기록",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        Container(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: meals.length,
                            itemBuilder: (context, index) {
                              return Container(
                                width: 120,
                                margin: EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  image: DecorationImage(
                                    image: FileImage(meals[index].image),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: 32),
                      ],

                      // 영양소 섭취 현황
                      Text(
                        "오늘의 영양소 섭취량",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: () {
                            var entries = dailyIntake.entries.toList();
                            entries.sort((a, b) {
                              double percentageA = (a.value / (averageDailyRequirements[a.key] ?? 100)) * 100;
                              double percentageB = (b.value / (averageDailyRequirements[b.key] ?? 100)) * 100;
                              return percentageB.compareTo(percentageA);
                            });
                            return entries.map((entry) => NutrientGauge(
                              label: entry.key,
                              currentValue: entry.value,
                              mealsPerDay: mealsPerDay,
                              isDailyTotal: true,
                            )).toList();
                          }(),
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
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: AppTheme.primaryColor,
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
