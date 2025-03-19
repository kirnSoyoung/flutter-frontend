import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/data_manager.dart';
import '../utils/nutrition_standards.dart';

/// 📌 영양제 추천 페이지
class SupplementPage extends StatefulWidget {
  @override
  _SupplementPageState createState() => _SupplementPageState();
}

class _SupplementPageState extends State<SupplementPage> {
  Map<String, double> weeklyIntake = {}; // 일주일간 섭취한 영양소
  List<MapEntry<String, double>> topDeficiencies = []; // 부족한 영양소 TOP 3

  @override
  void initState() {
    super.initState();
    _calculateWeeklyDeficiencies();
  }

  /// ✅ 최근 7일간의 섭취 영양소를 계산하여 부족한 영양소 분석
  void _calculateWeeklyDeficiencies() {
    final dataManager = Provider.of<DataManager>(context, listen: false);
    DateTime today = DateTime.now();

    // 1️⃣ 영양소 총량 초기화
    Map<String, double> totalIntake = { for (var key in averageDailyRequirements.keys) key: 0.0 };

    // 2️⃣ 최근 7일간의 섭취량 누적
    for (int i = 0; i < 7; i++) {
      DateTime day = today.subtract(Duration(days: i));
      List meals = dataManager.getMealsForDate(day) ?? [];

      for (var meal in meals) {
        meal.nutrients.forEach((key, value) {
          if (totalIntake.containsKey(key)) {
            totalIntake[key] = totalIntake[key]! + value;
          }
        });
      }
    }

    // 3️⃣ 부족한 영양소 계산 (권장량 대비)
    Map<String, double> deficiencies = {};
    averageDailyRequirements.forEach((key, requiredAmount) {
      double consumedAmount = totalIntake[key] ?? 0.0;
      double requiredWeekly = requiredAmount * 7; // 일주일 권장량
      if (consumedAmount < requiredWeekly * 0.8) { // 80% 이하일 때 부족 판정
        deficiencies[key] = requiredWeekly - consumedAmount;
      }
    });

    // 4️⃣ 부족한 영양소 TOP 3 선정
    List<MapEntry<String, double>> sortedDeficiencies = deficiencies.entries.toList();
    sortedDeficiencies.sort((a, b) => b.value.compareTo(a.value)); // 부족한 정도 기준 내림차순 정렬

    setState(() {
      weeklyIntake = totalIntake;
      topDeficiencies = sortedDeficiencies.take(3).toList(); // 가장 부족한 영양소 3개
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("영양제 추천")),
      body: SingleChildScrollView( // 🔥 스크롤 가능하게 수정해서 Overflow 해결
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📌 부족한 영양소 TOP 3 추천
            for (var deficiency in topDeficiencies)
              _buildSupplementSection(deficiency.key),
          ],
        ),
      ),
    );
  }

  /// 📌 부족한 영양소에 따른 추천 영양제 리스트 UI
  Widget _buildSupplementSection(String nutrient) {
    // (추후 API 연결 시 서버에서 가져오도록 변경)
    Map<String, List<Map<String, String>>> supplementData = {
      "비타민 C": [
        {"name": "비타민C 1000mg", "image": "https://via.placeholder.com/100", "url": "https://example.com/c1"},
        {"name": "고함량 비타민C", "image": "https://via.placeholder.com/100", "url": "https://example.com/c2"},
      ],
      "칼슘": [
        {"name": "칼슘+마그네슘", "image": "https://via.placeholder.com/100", "url": "https://example.com/ca1"},
        {"name": "칼슘 보충제", "image": "https://via.placeholder.com/100", "url": "https://example.com/ca2"},
      ],
      "오메가-3": [
        {"name": "오메가-3 1000mg", "image": "https://via.placeholder.com/100", "url": "https://example.com/o1"},
        {"name": "순수 오메가-3", "image": "https://via.placeholder.com/100", "url": "https://example.com/o2"},
      ],
      "철분": [
        {"name": "철분제 20mg", "image": "https://via.placeholder.com/100", "url": "https://example.com/f1"},
        {"name": "여성용 철분", "image": "https://via.placeholder.com/100", "url": "https://example.com/f2"},
      ],
      "비타민 D": [
        {"name": "비타민D 2000IU", "image": "https://via.placeholder.com/100", "url": "https://example.com/d1"},
        {"name": "비타민D 5000IU", "image": "https://via.placeholder.com/100", "url": "https://example.com/d2"},
      ],
    };

    List<Map<String, String>> supplements = supplementData[nutrient] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$nutrient 영양제 추천",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),

        // 📌 가로 스크롤 가능한 영양제 리스트
        SizedBox(
          height: 150, // 이미지 크기에 맞춰 조정
          child: ListView(
            scrollDirection: Axis.horizontal, // 가로 스크롤
            children: supplements.map((supplement) {
              return GestureDetector(
                onTap: () {
                  // 🔥 영양제 클릭 시 해당 URL로 이동
                  _openSupplementPage(supplement["url"]!);
                },
                child: Container(
                  width: 120,
                  margin: EdgeInsets.only(right: 10),
                  child: Column(
                    children: [
                      Image.network(supplement["image"]!, width: 100, height: 100),
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
  }

  /// 🔥 외부 영양제 구매 페이지로 이동하는 함수
  void _openSupplementPage(String url) {
    // 추후 웹뷰나 인앱 브라우저로 확장 가능
    print("✅ 이동: $url");
  }
}
