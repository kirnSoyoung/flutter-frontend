import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../models/user_model.dart';
import '../models/meal_model.dart';

/// SharedPreferences를 활용한 사용자 정보 관리 클래스
class SharedPrefs {

  static const String mealKey = 'meal_records';

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

  static Future<List<User>> getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final String? storedUsers = prefs.getString('users');

    if (storedUsers == null || storedUsers.isEmpty) return [];
    try {
      return (jsonDecode(storedUsers) as List<dynamic>)
          .map((user) => User.fromJson(user))
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveUser(User user) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? usersJson = prefs.getString("users");

    List<User> users = [];
    if (usersJson != null) {
      users = (jsonDecode(usersJson) as List)
          .map((data) => User.fromJson(data))
          .toList();
    }

    users.add(user);

    await prefs.setString("users", jsonEncode(users.map((u) => u.toJson()).toList()));
  }

  /// 자동 로그인 정보 저장
  static Future<void> saveLoginInfo(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('loggedInEmail', email);
    prefs.setString('loggedInPassword', password);
  }

  static Future<User?> getLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('loggedInEmail');
    String? password = prefs.getString('loggedInPassword');

    if (email == null || password == null) return null;

    List<User> users = await getUsers();
    return users.firstWhere(
          (user) => user.email == email && user.password == password,
      orElse: () => User(
        email: "",
        password: "",
        gender: "",
        age: 0,
        height: 0,
        weight: 0,
        activityLevel: "",
      ),
    );
  }

  /// 로그아웃 (자동 로그인 정보 삭제)
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('loggedInEmail');
    await prefs.remove('loggedInPassword');
  }


  /// 테스트용-데이터 삭제 버튼
  void resetMeals() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('meal_records'); // 우리가 저장했던 키
    print('✅ 모든 저장된 식단 데이터를 삭제했습니다.');
  }
}
