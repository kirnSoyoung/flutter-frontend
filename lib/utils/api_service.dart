import '../models/user_model.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/shared_prefs.dart';
import '../utils/test_nutrients.dart';

class ApiService {
  static const String baseUrl = "http://54.253.61.191:8000";

  static const List<String> nutrDb = [
    '에너지', '탄수화물', '식이섬유', '단백질', '리놀레산', '알파-리놀렌산', 'EPA+DHA',
    '메티오닌', '류신', '이소류신', '발린', '라이신', '페닐알라닌+티로신', '트레오닌', '트립토판', '히스티딘',
    '비타민A', '비타민D', '비타민E', '비타민K', '비타민C', '비타민B1', '비타민B2', '나이아신', '비타민B6',
    '비타민B12', '엽산', '판토텐산', '비오틴', '칼슘', '인', '나트륨', '염소', '칼륨', '마그네슘', '철',
    '아연', '구리', '망간', '요오드', '셀레늄', '몰리브덴', '크롬'
  ];

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

  /// 사용자별 영양소 저장
  static Future<bool> saveUserNutrients(Map<String, double> nutrients, String date) async {

      final user = await SharedPrefs.getLoggedInUser();
      if (user == null) return false;

      final nutrientsList = nutrDb.map((key) => nutrients[key] ?? 0.0).toList();

      final response = await http.post(
        Uri.parse("$baseUrl/database/user/save"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': user.userId,
          'date': date,
          'nutrients': nutrientsList,
        }),
      );

      if (response.statusCode != 404) {
        print("✅ 사용자 영양소 서버 저장 성공 (status: ${response.statusCode})");
        return true;
      } else {
        print("❌ 사용자 영양소 서버 저장 실패 (404 Not Found)");
        return false;
      }
  }

  /// 사용자별 영양소 삭제
  static Future<bool> deleteUserNutrients(Map<String, double> nutrients, String date) async {
    try {
      final user = await SharedPrefs.getLoggedInUser();
      if (user == null) return false;

      // 서버에 보낼 nutrient 배열 생성
      final nutrientsList = nutrDb.map((key) => nutrients[key] ?? 0.0).toList();

      final response = await http.post(
        Uri.parse("$baseUrl/database/user/delete"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': user.userId,
          'date': date,
          'nutrients': nutrientsList,
        }),
      );

      if (response.statusCode == 200) {
        print("✅ 삭제된 영양소 서버에 전송 완료");
        return true;
      } else {
        print("❌ 삭제 요청 실패: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("❌ deleteUserNutrients 예외 발생: $e");
      return false;
    }
  }


  static Future<bool> registerUser(User user) async {
    try {
      final uri = Uri.parse("$baseUrl/database/user/register")
          .replace(queryParameters: {'userid': user.userId});

      final genderMap = {
        "남성": "male",
        "여성": "female",
      };


      // 문자열 활동 수준을 수치로 변환
      final Map<String, double> activityLevelFactors = {
        "낮음": 1.2,
        "보통": 1.5,
        "높음": 1.725,
        "매우 높음": 1.9,
      };

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'gender': genderMap[user.gender] ?? "male",
          'age': user.age.toString(),
          'height': user.height.toString(),
          'weight': user.weight.toString(),
          'act_level': activityLevelFactors[user.activityLevel]?.toString() ?? "1.5",
        }),
      );

      if (response.statusCode == 200) {
        print("✅ 회원가입 성공");
        return true;
      } else if (response.statusCode == 409) {
        print("❌ 아이디 중복됨");
        return false;
      } else {
        print("❌ 기타 에러: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("❌ registerUser 예외 발생: $e");
      return false;
    }
  }


  static Future<bool> saveUserProfile(User user) async {
    try {
      final uri = Uri.parse("$baseUrl/database/user/profile")
          .replace(queryParameters: {'userid': user.userId});

      final genderMap = {
        "남성": "male",
        "여성": "female",
      };

      final activityLevelFactors = {
        "낮음": 1.2,
        "보통": 1.5,
        "높음": 1.725,
        "매우 높음": 1.9,
      };

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'gender': genderMap[user.gender] ?? "male",
          'age': user.age.toString(),
          'height': user.height.toString(),
          'weight': user.weight.toString(),
          'act_level': activityLevelFactors[user.activityLevel]?.toString() ?? "1.5",
        }),
      );

      if (response.statusCode == 200) {
        print("✅ 프로필 저장 성공");
        return true;
      } else {
        print("❌ 프로필 저장 실패: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("❌ saveUserProfile 예외 발생: $e");
      return false;
    }
  }


  /// 영양제 추천 받아오기
  static Future<Map<String, List<Map<String, dynamic>>>> getRecommendedSupplements() async {
    try {
      final user = await SharedPrefs.getLoggedInUser();
      if (user == null) return {};

      final response = await http.get(
        Uri.parse("$baseUrl/supplements/recommend/${Uri.encodeComponent(user.userId)}"),
      );

      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> raw = jsonDecode(decoded);

        final result = <String, List<Map<String, dynamic>>>{};

        raw.forEach((category, items) {
          result[category] = (items as List)
              .whereType<Map>()
              .map((e) => e.cast<String, dynamic>())
              .toList();
        });

        return result;
      } else {
        print("❌ 추천 실패: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ getRecommendedSupplements 예외: $e");
    }
    return {};
  }

}
