// lib/utils/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/shared_prefs.dart';
import '../utils/test_nutrients.dart';

class ApiService {
  static const String baseUrl = "http://54.253.61.191:8000";

  /// 음식 이름으로 영양소 조회
  static Future<Map<String, double>?> fetchNutrientsByName(String foodName) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/database/food_data:${Uri.encodeComponent(foodName)}"),
      );

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = jsonDecode(decodedBody);

        // 응답 구조: { nutrients: [ { name: ..., value: ... }, ... ] }
        final nutrientsList = data['nutrients'];
        final result = <String, double>{};

        if (nutrientsList is List) {
          for (var item in nutrientsList) {
            if (item is Map && item.containsKey('name') && item.containsKey('value')) {
              final name = item['name'].toString();
              final parsed = double.tryParse(item['value'].toString());
              if (parsed != null) result[name] = parsed;
            }
          }
        }
        return result;
      }
    } catch (e) {
      print("❌ fetchNutrientsByName 예외 발생: $e");
    }
    // 실패 시 테스트용 데이터 반환
    return testNutrients;
  }

  /// 사용자별 영양소 저장 (새로 추가)
  static Future<bool> saveUserNutrients(Map<String, double> nutrients, String date) async {
    try {
      final user = await SharedPrefs.getLoggedInUser();
      if (user == null) return false;
      final response = await http.post(
        Uri.parse("$baseUrl/database/user/save"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': user.email,
          'date': date,
          'nutrients': nutrients,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("❌ saveUserNutrients 예외 발생: $e");
      return false;
    }
  }

  /// 사용자별 영양소 삭제 (새로 추가)
  static Future<bool> deleteUserNutrients(String date) async {
    try {
      final user = await SharedPrefs.getLoggedInUser();
      if (user == null) return false;
      final response = await http.post(
        Uri.parse("$baseUrl/database/user/delete"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': user.email, 'date': date, 'nutrients': {}}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("❌ deleteUserNutrients 예외 발생: $e");
      return false;
    }
  }

  /// 영양제 추천 목록 조회
  static Future<List<Map<String, String>>> fetchSupplements(String nutrient) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/supplements?nutrient=${Uri.encodeComponent(nutrient)}"),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map<Map<String, String>>((item) => {
          'name': item['name'],
          'image': item['image'],
          'url': item['url'],
        }).toList();
      }
    } catch (e) {
      print("❌ fetchSupplements 예외 발생: $e");
    }
    return [];
  }
}
