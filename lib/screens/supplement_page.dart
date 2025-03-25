import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../utils/data_manager.dart';
import '../utils/api_service.dart';


const List<Map<String, String>> dummySupplements = [
  {
    "name": "테스트 영양제 A",
    "image": "https://via.placeholder.com/100",
    "url": "https://example.com/supplementA",
  },
  {
    "name": "테스트 영양제 B",
    "image": "https://via.placeholder.com/100",
    "url": "https://example.com/supplementB",
  },
  {
    "name": "테스트 영양제 C",
    "image": "https://via.placeholder.com/100",
    "url": "https://example.com/supplementC",
  },
];


class SupplementPage extends StatefulWidget {
  @override
  _SupplementPageState createState() => _SupplementPageState();
}

class _SupplementPageState extends State<SupplementPage> {
  List<String> topDeficiencies = [];

  @override
  void initState() {
    super.initState();
    _calculateWeeklyDeficiencies();
  }

  /// ✅ 영양소 결핍 계산 로직
  void _calculateWeeklyDeficiencies() {
    final dataManager = Provider.of<DataManager>(context, listen: false);
    final now = DateTime.now();
    final lastWeek = now.subtract(Duration(days: 7));

    Map<String, double> totalNutrients = {};

    for (int i = 0; i < 7; i++) {
      final date = lastWeek.add(Duration(days: i));
      final meals = dataManager.getMealsForDate(date) ?? [];

      for (var meal in meals) {
        meal.nutrients.forEach((key, value) {
          totalNutrients[key] = (totalNutrients[key] ?? 0) + value;
        });
      }
    }

    // 기준 섭취량
    final standards = {
      "비타민 C": 100.0,
      "철분": 18.0,
      "칼슘": 1000.0,
      "마그네슘": 400.0,
      "비타민 D": 15.0,
    };

    Map<String, double> deficiencies = {};
    standards.forEach((key, standard) {
      final consumed = totalNutrients[key] ?? 0;
      deficiencies[key] = (standard - consumed).clamp(0.0, double.infinity);
    });

    final sorted = deficiencies.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    setState(() {
      topDeficiencies = sorted.take(3).map((e) => e.key).toList();
    });
  }

  Future<List<Map<String, String>>> fetchSupplementsFromServer(String nutrient) async {
    try {
      final response = await http.get(Uri.parse(
        "http://54.253.61.191:8000//supplements?nutrient=${Uri.encodeComponent(nutrient)}",
      ));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map<Map<String, String>>((item) => {
          "name": item['name'],
          "image": item['image'],
          "url": item['url'],
        }).toList();
      } else {
        print("❌ 서버 응답 오류: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ 영양제 API 호출 오류: $e");
    }

    return [];
  }

  void _openSupplementPage(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      print("❌ URL 열기 실패: $url");
    }
  }

  /// ✅ 추천 리스트 UI
  Widget _buildSupplementSection(String nutrient) {
    return FutureBuilder<List<Map<String, String>>>(
      future: ApiService.fetchSupplements(nutrient),
      builder: (context, snapshot) {
        bool hasData = snapshot.hasData && snapshot.data!.isNotEmpty;
        final supplements = hasData ? snapshot.data! : dummySupplements;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$nutrient 영양제 추천",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            SizedBox(
              height: 150,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: supplements.map((supplement) {
                  return GestureDetector(
                    onTap: () {
                      if (hasData) {
                        _openSupplementPage(supplement["url"]!);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("URL이 아직 준비되지 않았습니다.")),
                        );
                      }
                    },
                    child: Container(
                      width: 120,
                      margin: EdgeInsets.only(right: 10),
                      child: Column(
                        children: [
                          Image.network(
                            supplement["image"]!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                          SizedBox(height: 5),
                          Text(
                            supplement["name"]!,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 20),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("영양제 추천")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: topDeficiencies.isEmpty
            ? Center(child: Text("최근 일주일간 분석할 식단이 없습니다."))
            : ListView(
          children: topDeficiencies
              .map((nutrient) => _buildSupplementSection(nutrient))
              .toList(),
        ),
      ),
    );
  }
}
