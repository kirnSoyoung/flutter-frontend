import 'dart:io';
import 'package:flutter/material.dart';
import '../models/meal_model.dart';

/// 앱에서 식단 데이터를 관리하는 싱글턴 클래스
class DataManager extends ChangeNotifier {
  static final DataManager _instance = DataManager._internal();
  factory DataManager() => _instance;
  DataManager._internal();

  final Map<DateTime, List<Meal>> _mealRecords = <DateTime, List<Meal>>{}; // 날짜별 식단 기록

  /// 새로운 식단을 추가하는 함수
  void addMeal(DateTime date, File image, Map<String, double> nutrients, String mealName) {
    DateTime normalizedDate = DateTime(date.year, date.month, date.day); // 날짜 정규화 (시간 제외)
    _mealRecords[normalizedDate] ??= [];
    _mealRecords[normalizedDate]!.add(Meal(
      image: image,
      nutrients: nutrients,
      mealName: mealName,
    ));
    notifyListeners(); // UI 업데이트를 위해 리스너들에게 변경 사항 알림
  }

  /// 특정 날짜의 식단을 가져오는 함수
  List<Meal>? getMealsForDate(DateTime date) {
    DateTime normalizedDate = DateTime(date.year, date.month, date.day);
    return _mealRecords[normalizedDate];
  }

  /// 모든 식단 데이터를 반환
  Map<DateTime, List<Meal>> get allMeals => _mealRecords;
}
