import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://54.253.61.191:8000";

  static Future<Map<String, double>?> fetchNutrientsByName(String foodName) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/food/nutrients?food_name=${Uri.encodeComponent(foodName)}"));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return Map<String, double>.from(data['nutrients']);
        }
      }
    } catch (e) {
      print("❌ fetchNutrientsByName 예외 발생: $e");
    }
    return null;
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
