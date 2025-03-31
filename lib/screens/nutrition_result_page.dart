import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/meal_model.dart';
import '../utils/api_service.dart';
import '../utils/data_manager.dart';
import '../utils/nutrition_standards.dart';
import '../utils/food_nutrient_cache.dart';
import '../utils/test_nutrients.dart';
import '../widgets/nutrient_gauge.dart';
import 'diet_recognition_page.dart';

class NutritionResultPage extends StatefulWidget {
  final String imagePath;
  final Map<String, double> nutrients;
  final bool isFromHistory;
  final DateTime? selectedDate;
  final String mealName;

  NutritionResultPage({
    required this.imagePath,
    required this.nutrients,
    required this.mealName,
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
    final cached = FoodNutrientCache.get(widget.mealName);
    if (cached != null) {
      _nutrients = cached;
    } else {
      // ✅ 지금은 테스트용 데이터 사용
      final test = testNutrients; // ← 테스트 데이터
      _nutrients = test;

      // 나중에 서버 연동되면 이 부분 활성화
      /*
      final data = await ApiService.fetchNutrientsByName(widget.mealName);
      if (data != null) {
        _nutrients = data;
        FoodNutrientCache.save(widget.mealName, data);
      }
      */
    FoodNutrientCache.save(widget.mealName, test);
  }

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
      widget.mealName,
    );
    setState(() {
      _isSaved = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('식단이 저장되었습니다.')),
    );
  }

  void _goBack() {
    Navigator.pop(context);
  }

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
              List<Meal>? meals = dataManager.getMealsForDate(mealDate);
              if (meals != null) {
                meals.removeWhere((meal) => meal.image.path == widget.imagePath);
                if (meals.isEmpty) {
                  dataManager.allMeals.remove(mealDate);
                }
                dataManager.saveMeals();
                dataManager.notifyListeners();
              }
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
    // 🔽 버튼 UI 스타일 수정 (이미지 참고 기반)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: widget.isFromHistory ? _deleteMeal : _saveMeal,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.isFromHistory ? Colors.red : Color(0xFF4CAF50),
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
        SizedBox(height: 12),
        Center(
          child: GestureDetector(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => DietRecognitionPage(
                    image: File(widget.imagePath),
                    selectedDate: widget.selectedDate,
                    initialMealName: widget.mealName,
                    isEditing: true,
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
                  Text(
                    "현재 등록된 식단: ${widget.mealName}",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
