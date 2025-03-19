import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/meal_model.dart';

class DataManager extends ChangeNotifier {
  static final DataManager _instance = DataManager._internal();
  factory DataManager() => _instance;
  DataManager._internal();

  final Map<DateTime, List<Meal>> _mealRecords = <DateTime, List<Meal>>{};

  /// 새로운 식단을 추가하는 함수 (SharedPreferences에도 저장)
  void addMeal(DateTime date, File image, Map<String, double> nutrients, String mealName) {
    DateTime normalizedDate = DateTime(date.year, date.month, date.day);
    _mealRecords[normalizedDate] ??= [];
    _mealRecords[normalizedDate]!.add(Meal(image: image, nutrients: nutrients, mealName: mealName));

    saveMeals(); // 저장 기능 추가
    notifyListeners();
  }

  /// ✅ 식단 삭제 후 저장하는 기능 추가
  void deleteMeal(DateTime date, String imagePath) {
    DateTime normalizedDate = DateTime(date.year, date.month, date.day);

    if (_mealRecords.containsKey(normalizedDate)) {
      _mealRecords[normalizedDate]!.removeWhere((meal) => meal.image.path == imagePath);

      // ✅ 해당 날짜의 식단이 모두 삭제되었다면, 날짜 자체를 `_mealRecords`에서 제거
      if (_mealRecords[normalizedDate]!.isEmpty) {
        _mealRecords.remove(normalizedDate);
      }

      saveMeals(); // ✅ 삭제 후 데이터 저장
      notifyListeners(); // ✅ UI 업데이트
    }
  }


  /// 특정 날짜의 식단을 가져오는 함수
  List<Meal>? getMealsForDate(DateTime date) {
    DateTime normalizedDate = DateTime(date.year, date.month, date.day);
    return _mealRecords[normalizedDate];
  }

  /// 모든 식단 데이터를 반환
  Map<DateTime, List<Meal>> get allMeals => _mealRecords;

  /// 식단 데이터를 SharedPreferences에 저장하는 함수
  Future<void> saveMeals() async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> jsonMeals = {};

    _mealRecords.forEach((date, meals) {
      jsonMeals[date.toIso8601String()] = meals.map((meal) {
        return {
          "imagePath": meal.image.path,
          "nutrients": meal.nutrients,
          "mealName": meal.mealName,
        };
      }).toList();
    });

    await prefs.setString('mealRecords', jsonEncode(jsonMeals));
  }

  /// SharedPreferences에서 데이터를 불러오는 함수
  Future<void> loadMeals() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedMeals = prefs.getString('mealRecords');

    if (savedMeals == null) return;

    Map<String, dynamic> jsonMeals = jsonDecode(savedMeals);
    jsonMeals.forEach((date, meals) {
      DateTime parsedDate = DateTime.parse(date);
      _mealRecords[parsedDate] = (meals as List).map((meal) {
        return Meal(
          image: File(meal["imagePath"]),
          nutrients: Map<String, double>.from(meal["nutrients"]),
          mealName: meal["mealName"],
        );
      }).toList();
    });

    notifyListeners();
  }
}
