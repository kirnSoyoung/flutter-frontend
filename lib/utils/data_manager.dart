import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/meal_model.dart';
import 'shared_prefs.dart';

class DataManager extends ChangeNotifier {
  final Map<DateTime, List<Meal>> _mealRecords = {};

  Map<DateTime, List<Meal>> get allMeals => _mealRecords;

  List<Meal>? getMealsForDate(DateTime date) {
    DateTime normalizedDate = DateTime(date.year, date.month, date.day);
    return _mealRecords[normalizedDate];
  }

  void addMeal(DateTime date, File image, Map<String, Map<String, double>> perFoodNutrients, List<String> mealNames) {
    DateTime normalizedDate = DateTime(date.year, date.month, date.day);
    _mealRecords[normalizedDate] ??= [];

    _mealRecords[normalizedDate]!.add(
      Meal(
        image: image,
        nutrients: perFoodNutrients, // ✅ 전체 합산이 아닌 음식별 Map 저장
        mealNames: mealNames,
      ),
    );

    saveMeals();
    notifyListeners();
  }

  void deleteMealByImagePath(DateTime date, String imagePath) {
    DateTime normalizedDate = DateTime(date.year, date.month, date.day);
    print("🗑️ 삭제 시도: $normalizedDate, path: $imagePath");

    if (_mealRecords.containsKey(normalizedDate)) {
      _mealRecords[normalizedDate]!.forEach((meal) {
        print("🔍 비교 대상 path: ${meal.image.path}");
      });

      _mealRecords[normalizedDate]!.removeWhere(
            (meal) => meal.image.path.trim() == imagePath.trim(),
      );

      if (_mealRecords[normalizedDate]!.isEmpty) {
        _mealRecords.remove(normalizedDate);
      }

      saveMeals();
      notifyListeners();
    }
  }

  void deleteMeal(Meal target, DateTime date) {
    DateTime normalizedDate = DateTime(date.year, date.month, date.day);
    print("🗑️ 삭제 시도 (Meal): $normalizedDate, path: ${target.image.path}");

    if (_mealRecords.containsKey(normalizedDate)) {
      _mealRecords[normalizedDate]!.forEach((meal) {
        print("🔍 비교 대상: ${meal.image.path} / ${meal.mealNames}");
      });

      _mealRecords[normalizedDate]!.removeWhere((meal) =>
      meal.image.path.trim() == target.image.path.trim() &&
          meal.mealNames.toString() == target.mealNames.toString()
      );

      if (_mealRecords[normalizedDate]!.isEmpty) {
        _mealRecords.remove(normalizedDate);
      }

      saveMeals();
      notifyListeners();
    }
  }


  void saveMeals() {
    SharedPrefs.saveMeals(_mealRecords);
  }

  Future<void> loadMeals() async {
    Map<DateTime, List<Meal>> loaded = await SharedPrefs.loadMeals();
    _mealRecords.clear();
    _mealRecords.addAll(loaded);
    notifyListeners();
  }
}
