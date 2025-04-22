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

  void addMeal(
      DateTime date,
      File image,
      Map<String, Map<String, double>> perFoodNutrients,
      List<String> mealNames,
      Map<String, double> servings,
      ) {
    DateTime normalizedDate = DateTime(date.year, date.month, date.day);
    _mealRecords[normalizedDate] ??= [];

    _mealRecords[normalizedDate]!.add(
      Meal(
        image: image,
        nutrients: perFoodNutrients,
        mealNames: mealNames,
        servings: servings,
      ),
    );

    saveMeals();
    notifyListeners();
  }

  void deleteMealByImagePath(DateTime date, String imagePath) {
    DateTime normalizedDate = DateTime(date.year, date.month, date.day);
    if (_mealRecords.containsKey(normalizedDate)) {
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
    if (_mealRecords.containsKey(normalizedDate)) {
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
