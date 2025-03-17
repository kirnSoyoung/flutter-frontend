import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';

/// SharedPreferences를 활용한 사용자 정보 관리 클래스
class SharedPrefs {
  /// 저장된 사용자 목록을 가져오는 함수
  static Future<List<User>> getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final String? storedUsers = prefs.getString('users');

    if (storedUsers == null || storedUsers.isEmpty) return []; // 저장된 데이터가 없으면 빈 리스트 반환
    try {
      return (jsonDecode(storedUsers) as List<dynamic>)
          .map((user) => User.fromJson(user))
          .toList();
    } catch (e) {
      return []; // JSON 변환 실패 시 빈 리스트 반환
    }
  }

  /// 새로운 사용자 정보를 저장하는 함수
  static Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    List<User> users = await getUsers();

    // 기존 사용자 정보가 있으면 업데이트, 없으면 추가
    int existingUserIndex = users.indexWhere((u) => u.email == user.email);
    if (existingUserIndex != -1) {
      users[existingUserIndex] = user;
    } else {
      users.add(user);
    }

    await prefs.setString('users', jsonEncode(users.map((u) => u.toJson()).toList()));

    // 자동 로그인 정보 업데이트
    await prefs.setString('loggedInEmail', user.email);
    await prefs.setString('loggedInPassword', user.password);
  }

  /// 자동 로그인 정보 저장
  static Future<void> saveLoginInfo(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('loggedInEmail', email);
    prefs.setString('loggedInPassword', password);
  }

  /// 자동 로그인 정보 불러오기
  static Future<User?> getLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('loggedInEmail');
    String? password = prefs.getString('loggedInPassword');

    if (email == null || password == null) return null;

    List<User> users = await getUsers();
    return users.firstWhere(
          (user) => user.email == email && user.password == password,
      orElse: () => User(
        email: "", password: "", gender: "", age: 0, height: 0, weight: 0, activityLevel: "",
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
