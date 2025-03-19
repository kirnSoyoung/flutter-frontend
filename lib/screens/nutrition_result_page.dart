import 'package:flutter/material.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/data_manager.dart';
import '../widgets/nutrient_gauge.dart';
import 'diet_recognition_page.dart';
import '../models/meal_model.dart';

/// 사용자가 선택한 식사의 영양소 분석 결과를 보여주는 페이지
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
  bool _mealAdded = false;
  bool _isLoading = true;
  Map<String, double> _nutrients = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_mealAdded && !widget.isFromHistory) {
      Provider.of<DataManager>(context, listen: false).addMeal(
        widget.selectedDate ?? DateTime.now(),
        File(widget.imagePath),
        widget.nutrients,
        widget.mealName,
      );
      _mealAdded = true;
    }
    _fetchNutrientData();
  }

  /// ✅ 서버에서 음식 영양소 데이터를 불러오는 함수
  Future<void> _fetchNutrientData() async {
    try {
      final response = await http.get(Uri.parse(
          "https://yourserver.com/food/nutrients?food_name=${Uri.encodeComponent(widget.mealName)}"));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          setState(() {
            _nutrients = Map<String, double>.from(data['nutrients']);
            _isLoading = false;
          });
        } else {
          print("❌ 서버 응답 실패: ${data['message']}");
        }
      } else {
        print("❌ 서버 오류: ${response.reasonPhrase}");
      }
    } catch (e) {
      print("❌ API 요청 중 오류 발생: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 이전 화면으로 이동
  void _goBack() {
    Navigator.pop(context);
  }

  /// 식단 수정 페이지로 이동
  void _editMeal() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DietRecognitionPage(
          image: File(widget.imagePath),
          selectedDate: widget.selectedDate,
          initialMealName: widget.mealName,
          isEditing: true,
        ),
      ),
    ).then((_) {
      setState(() {});
    });
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _goBack();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("영양소 분석 결과"),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: _goBack,
          ),
          actions: [
            if (widget.isFromHistory) ...[
              IconButton(
                icon: Icon(Icons.edit, color: Colors.blue),
                onPressed: _editMeal,
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: _deleteMeal,
              ),
            ],
          ],
        ),
        body: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              Image.file(File(widget.imagePath), width: double.infinity, height: 250, fit: BoxFit.cover),
              SizedBox(height: 20),

              Text(
                "현재 등록된 식단: ${widget.mealName}",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),

              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : Expanded(
                child: ListView(
                  children: _nutrients.entries.map((entry) {
                    return NutrientGauge(
                      label: entry.key,
                      currentValue: entry.value,
                      mealsPerDay: 3,
                      isDailyTotal: false,
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
