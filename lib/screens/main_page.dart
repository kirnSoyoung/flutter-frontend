import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/data_manager.dart';
import '../utils/nutrition_standards.dart';
import '../widgets/image_picker_widget.dart';
import '../widgets/nutrient_gauge.dart';
import 'diet_recognition_page.dart';

class HomePage extends StatefulWidget {
  final String email;

  HomePage(this.email);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final int mealsPerDay = 3; // 하루 식사 횟수 (기본 3회)

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
      appBar: AppBar(title: Text("홈")),
      body: Column(
        children: [
          Expanded(
            child: Consumer<DataManager>(
              builder: (context, dataManager, child) {
                DateTime today = DateTime.now();
                List meals = dataManager.getMealsForDate(today) ?? [];

                // 하루 영양소 총량 계산
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

                return Column(
                  children: [
                    SizedBox(height: 20),
                    Text("오늘의 영양소 섭취량", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 20),
                    Expanded(
                      child: ListView(
                        children: dailyIntake.entries.map((entry) {
                          return NutrientGauge(
                            label: entry.key,
                            currentValue: entry.value,
                            mealsPerDay: mealsPerDay,
                            isDailyTotal: true,
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          ImagePickerWidget(onImageSelected: setImage),
        ],
      ),
    );
  }
}
