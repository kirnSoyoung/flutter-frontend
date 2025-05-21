import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../models/meal_model.dart';

/// SharedPreferences를 활용한 사용자 정보 관리 클래스
class SharedPrefs {
  static const String mealKey = 'meal_records';
  static const String userKey = 'users';
  static const String loggedInKey = 'loggedInUser';

  /// 식단 정보 저장
  static Future<void> saveMeals(Map<DateTime, List<Meal>> meals) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> jsonMap = {};

    meals.forEach((date, mealList) {
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);
      jsonMap[formattedDate] = mealList.map((meal) => meal.toJson()).toList();
    });

    final encoded = jsonEncode(jsonMap);
    await prefs.setString(mealKey, encoded);
  }

  /// 식단 정보 불러오기
  static Future<Map<DateTime, List<Meal>>> loadMeals() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<DateTime, List<Meal>> loaded = {};
    final encoded = prefs.getString(mealKey);
    if (encoded == null) return loaded;

    final decoded = jsonDecode(encoded) as Map<String, dynamic>;
    decoded.forEach((dateStr, mealListJson) {
      final date = DateFormat('yyyy-MM-dd').parse(dateStr);
      final mealList = (mealListJson as List).map((json) => Meal.fromJson(json)).toList();
      loaded[date] = mealList;
    });

    return loaded;
  }

  /// 모든 사용자 목록 가져오기
  static Future<List<User>> getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final String? storedUsers = prefs.getString(userKey);

    if (storedUsers == null || storedUsers.isEmpty) return [];
    try {
      return (jsonDecode(storedUsers) as List<dynamic>)
          .map((user) => User.fromJson(user))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// 사용자 저장 (기존 사용자 ID 제거 후 업데이트)
  static Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    String? usersJson = prefs.getString(userKey);

    List<User> users = [];
    if (usersJson != null) {
      users = (jsonDecode(usersJson) as List)
          .map((data) => User.fromJson(data))
          .toList();
    }

    users.removeWhere((u) => u.userId == user.userId);
    users.add(user);

    await prefs.setString(userKey, jsonEncode(users.map((u) => u.toJson()).toList()));
  }

  /// 로그인된 사용자 정보 저장
  static Future<void> saveLoggedInUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(loggedInKey, jsonEncode(user.toJson()));
  }

  /// 로그인된 사용자 정보 가져오기
  static Future<User?> getLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(loggedInKey);
    if (userJson == null) return null;

    try {
      return User.fromJson(jsonDecode(userJson));
    } catch (e) {
      return null;
    }
  }

  /// 로그아웃
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(loggedInKey);
  }

  /// 테스트용 데이터 리셋
  static Future<void> resetMeals() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(mealKey);
    print('✅ 모든 저장된 식단 데이터를 삭제했습니다.');
  }
}
