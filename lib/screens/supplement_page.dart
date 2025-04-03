import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';
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
  const SupplementPage({super.key});

  @override
  State<SupplementPage> createState() => _SupplementPageState();
}

class _SupplementPageState extends State<SupplementPage> {
  List<String> topDeficiencies = [];

  @override
  void initState() {
    super.initState();
    _calculateWeeklyDeficiencies();
  }

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

  Widget _buildSupplementSection(String nutrient) {
    return FutureBuilder<List<Map<String, String>>>(
      future: fetchSupplementsFromServer(nutrient),
      builder: (context, snapshot) {
        bool hasData = snapshot.hasData && snapshot.data!.isNotEmpty;
        final supplements = hasData ? snapshot.data! : dummySupplements;

        return Container(
          margin: EdgeInsets.only(bottom: 24),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nutrient,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 12),
              Row(
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
                      width: 100,
                      margin: EdgeInsets.only(right: 12),
                      child: Column(
                        children: [
                          if (supplement["image"] != null &&
                              supplement["image"]!.startsWith("http"))
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                supplement["image"]!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => SizedBox.shrink(),
                              ),
                            ),
                          SizedBox(height: 8),
                          Text(
                            supplement["name"]!,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.medical_services, color: AppTheme.primaryColor),
                    SizedBox(width: 8),
                    Text(
                      "영양제 추천",
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Expanded(
                child: topDeficiencies.isEmpty
                    ? Center(child: Text("최근 일주일간 분석할 식단이 없습니다."))
                    : ListView(
                  children: topDeficiencies
                      .map((nutrient) => _buildSupplementSection(nutrient))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}