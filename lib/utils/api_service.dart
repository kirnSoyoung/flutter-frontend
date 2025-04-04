import 'dart:convert';

import 'package:http/http.dart' as http;

import '../utils/test_nutrients.dart';

class ApiService {
  static const String baseUrl = "http://54.253.61.191:8000";

  static Future<Map<String, double>?> fetchNutrientsByName(String foodName) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/database/food_data:${Uri.encodeComponent(foodName)}"),
      );

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = jsonDecode(decodedBody);

        print("🔥 서버 응답 데이터: $data");

        final result = <String, double>{};

        if (data is List) {
          for (var item in data) {
            if (item is Map && item.containsKey('name') && item.containsKey('value')) {
              final name = item['name'].toString();
              final rawValue = item['value'];
              final parsed = double.tryParse(rawValue.toString());

              print("🔍 $name: $rawValue → \${parsed ?? '파싱 실패'}");

              if (parsed != null) {
                result[name] = parsed;
              }
            }
          }
        } else if (data is Map<String, dynamic>) {
          data.forEach((key, value) {
            final parsed = double.tryParse(value.toString());
            if (parsed != null) {
              result[key] = parsed;
            }
          });
        }

        print("🔥 파싱된 결과: $result");
        return result;
      }
    } catch (e) {
      print("❌ fetchNutrientsByName 예외 발생: $e");
    }

    print("⚠️ API 실패 또는 데이터 없음. 임시 testNutrients 사용");
    return testNutrients;
  }

  static Future<List<Map<String, String>>> fetchSupplements(String nutrient) async {
    try {
      final response = await http.get(Uri.parse(
        "$baseUrl/supplements?nutrient=${Uri.encodeComponent(nutrient)}",
      ));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map<Map<String, String>>((item) => {
          "name": item['name'],
          "image": item['image'],
          "url": item['url'],
        }).toList();
      }
    } catch (e) {
      print("❌ fetchSupplements 예외 발생: $e");
    }
    return [];
  }
}