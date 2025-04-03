import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/meal_model.dart';
import '../utils/data_manager.dart';
import '../utils/nutrition_standards.dart';
import '../widgets/nutrient_gauge.dart';
import 'diet_recognition_page.dart';

class NutritionResultPage extends StatefulWidget {
  final String imagePath;
  final Map<String, double> nutrients;
  final bool isFromHistory;
  final DateTime? selectedDate;
  final List<String> mealNames; // ✅ 리스트로 변경

  const NutritionResultPage({
    required this.imagePath,
    required this.nutrients,
    required this.mealNames,
    this.isFromHistory = false,
    this.selectedDate,
  });

  @override
  _NutritionResultPageState createState() => _NutritionResultPageState();
}

class _NutritionResultPageState extends State<NutritionResultPage> {
  bool _isLoading = true;
  bool _isSaved = false;
  Map<String, double> _nutrients = {};

  @override
  void initState() {
    super.initState();
    _loadNutrientData();
  }

  Future<void> _loadNutrientData() async {
    /*
    print("📋 서버에서 받은 nutrient 키들:");
    widget.nutrients.keys.forEach(print);

    print("🎯 우리가 사용하는 키 목록:");
    averageDailyRequirements.keys.forEach(print);
    */
    String normalizeKey(String raw) {
      return raw.replaceAll(RegExp(r'\s*\(.*?\)'), '').trim();
    }

    final filtered = <String, double>{};

    widget.nutrients.forEach((rawKey, value) {
      final normalized = normalizeKey(rawKey);
      if (averageDailyRequirements.containsKey(normalized)) {
        filtered[normalized] = value;
      } else {
        print("❌ 매칭 실패: '$normalized'");
      }
    });

    print("✅ 필터링 후 최종 nutrients:");
    print(filtered);

    _nutrients = filtered;
    setState(() => _isLoading = false);
  }




  void _saveMeal() {
    if (_isSaved) return;
    final dataManager = Provider.of<DataManager>(context, listen: false);
    final date = widget.selectedDate ?? DateTime.now();

    dataManager.addMeal(
      date,
      File(widget.imagePath),
      _nutrients,
      widget.mealNames,
    );
    setState(() => _isSaved = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('식단이 저장되었습니다.')),
    );
  }

  void _goBack() => Navigator.pop(context);

  void _deleteMeal() {
    final dataManager = Provider.of<DataManager>(context, listen: false);
    DateTime mealDate = widget.selectedDate ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("삭제 확인"),
        content: Text("정말로 이 식단을 삭제하시겠습니까?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("취소"),
          ),
          TextButton(
            onPressed: () {
              dataManager.deleteMealByImagePath(mealDate, widget.imagePath);
              Navigator.pop(context);
              _goBack();
            },
            child: Text("삭제", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: widget.isFromHistory ? _deleteMeal : _saveMeal,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.isFromHistory ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: Text(
              widget.isFromHistory ? "삭제하기" : "식단 저장하기",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: GestureDetector(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => DietRecognitionPage(
                    image: File(widget.imagePath),
                    selectedDate: widget.selectedDate,
                  ),
                ),
              );
            },
            child: Text(
              "다시 분석하기",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("영양소 분석 결과"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: _goBack,
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.file(
                    File(widget.imagePath),
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(height: 20),
                  Text("선택된 음식들:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: widget.mealNames.map((name) => Chip(
                      label: Text(name),
                      backgroundColor: Colors.green[100],
                    )).toList(),
                  ),
                  const SizedBox(height: 20),
                  Column(
                    children: averageDailyRequirements.entries.map((entry) {
                      final label = entry.key;
                      final current = _nutrients[label] ?? 0.0;
                      return NutrientGauge(
                        label: label,
                        currentValue: current,
                        mealsPerDay: 3,
                        isDailyTotal: false,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildBottomButtons(),
          ),
        ],
      ),
    );
  }
}
