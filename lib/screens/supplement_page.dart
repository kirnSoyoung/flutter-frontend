import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';
import '../utils/data_manager.dart';
import '../utils/api_service.dart';

const List<Map<String, String>> dummySupplements = [
  {
    'name': '테스트 영양제 A',
    'image': 'https://via.placeholder.com/100',
    'url': 'https://example.com/supplementA',
  },
  {
    'name': '테스트 영양제 B',
    'image': 'https://via.placeholder.com/100',
    'url': 'https://example.com/supplementB',
  },
  {
    'name': '테스트 영양제 C',
    'image': 'https://via.placeholder.com/100',
    'url': 'https://example.com/supplementC',
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

    Map<String, double> total = {};
    for (int i = 0; i < 7; i++) {
      final date = lastWeek.add(Duration(days: i));
      final meals = dataManager.getMealsForDate(date) ?? [];
      for (var meal in meals) {
        meal.nutrients.forEach((food, nutrientMap) {
          nutrientMap.forEach((nutrient, value) {
            total[nutrient] = (total[nutrient] ?? 0) + value;
          });
        });
      }
    }

    const standards = {
      '비타민 C': 100.0,
      '철분': 18.0,
      '칼슘': 1000.0,
      '마그네슘': 400.0,
      '비타민 D': 15.0,
    };

    final deficiencies = <String, double>{};
    standards.forEach((k, std) {
      final consumed = total[k] ?? 0;
      deficiencies[k] = (std - consumed).clamp(0.0, double.infinity);
    });

    final sorted = deficiencies.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    setState(() {
      topDeficiencies = sorted.take(3).map((e) => e.key).toList();
    });
  }

  void _openSupplementPage(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildSupplementSection(String nutrient) {
    return FutureBuilder<List<Map<String, String>>>(
      future: ApiService.fetchSupplements(nutrient),
      builder: (context, snapshot) {
        final hasData = snapshot.hasData && snapshot.data!.isNotEmpty;
        final supplements = hasData ? snapshot.data! : dummySupplements;

        return Container(
          margin: EdgeInsets.only(bottom: 24),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(nutrient, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              Row(
                children: supplements.map((supp) {
                  return GestureDetector(
                    onTap: () => _openSupplementPage(supp['url']!),
                    child: Container(
                      width: 100,
                      margin: EdgeInsets.only(right: 12),
                      child: Column(
                        children: [
                          if (supp['image']!.startsWith('http'))
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(supp['image']!, width: 100, height: 100, fit: BoxFit.cover),
                            ),
                          SizedBox(height: 8),
                          Text(
                            supp['name']!,
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
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
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
                    Text("영양제 추천", style: TextStyle(color: AppTheme.primaryColor, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Expanded(
                child: topDeficiencies.isEmpty
                    ? Center(child: Text("최근 일주일간 분석할 식단이 없습니다."))
                    : ListView(children: topDeficiencies.map(_buildSupplementSection).toList()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
