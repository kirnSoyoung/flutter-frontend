import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/meal_model.dart';

class DataManager extends ChangeNotifier {
  static final DataManager _instance = DataManager._internal();
  factory DataManager() => _instance;
  DataManager._internal();

  final Map<DateTime, List<Meal>> _mealRecords = {};

  void addMeal(DateTime date, File image, Map<String, double> nutrients, String mealName) {
    DateTime normalizedDate = DateTime(date.year, date.month, date.day);
    _mealRecords[normalizedDate] ??= [];
    _mealRecords[normalizedDate]!.add(
        Meal(image: image, nutrients: nutrients, mealName: mealName)
    );
    saveMeals();
    notifyListeners();
  }

  void deleteMeal(DateTime date, String imagePath) {
    DateTime normalizedDate = DateTime(date.year, date.month, date.day);
    if (_mealRecords.containsKey(normalizedDate)) {
      _mealRecords[normalizedDate]!.removeWhere((meal) => meal.image.path == imagePath);
      if (_mealRecords[normalizedDate]!.isEmpty) {
        _mealRecords.remove(normalizedDate);
      }
      saveMeals();
      notifyListeners();
    }
  }

  List<Meal>? getMealsForDate(DateTime date) {
    DateTime normalizedDate = DateTime(date.year, date.month, date.day);
    return _mealRecords[normalizedDate];
  }

  Map<DateTime, List<Meal>> get allMeals => _mealRecords;

  Future<void> saveMeals() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonMeals = {
      for (var entry in _mealRecords.entries)
        entry.key.toIso8601String(): entry.value.map((m) => m.toJson()).toList(),
    };
    await prefs.setString('mealRecords', jsonEncode(jsonMeals));
  }

  Future<void> loadMeals() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedMeals = prefs.getString('mealRecords');
    if (savedMeals == null) return;

    Map<String, dynamic> jsonMeals = jsonDecode(savedMeals);
    jsonMeals.forEach((date, meals) {
      DateTime parsedDate = DateTime.parse(date);
      _mealRecords[parsedDate] = (meals as List)
          .map((meal) => Meal.fromJson(meal))
          .toList();
    });

    notifyListeners();
  }
}
