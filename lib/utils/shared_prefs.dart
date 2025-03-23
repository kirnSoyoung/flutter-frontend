import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';

/// SharedPreferences를 활용한 사용자 정보 관리 클래스
class SharedPrefs {
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
    final prefs = await SharedPreferences.getInstance();
    List<User> users = await getUsers();

    final index = users.indexWhere((u) => u.email == user.email);
    if (index != -1) {
      users[index] = user;
    } else {
      users.add(user);
    }
    await prefs.setString(
      'users',
      jsonEncode(users.map((u) => u.toJson()).toList()),
    );
    await prefs.setString('loggedInEmail', user.email);
    await prefs.setString('loggedInPassword', user.password);
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
}
