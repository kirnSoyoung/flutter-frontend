import 'package:flutter/material.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../utils/data_manager.dart';
import '../widgets/nutrient_gauge.dart';
import 'diet_recognition_page.dart';
import '../models/meal_model.dart';

/// 사용자가 선택한 식사의 영양소 분석 결과를 보여주는 페이지
class NutritionResultPage extends StatefulWidget {
  final String imagePath; // 선택한 식사의 이미지 경로
  final Map<String, double> nutrients; // 분석된 영양소 정보
  final bool isFromHistory; // 기록에서 접근한 경우 (true) / 새로 추가된 경우 (false)
  final DateTime? selectedDate; // 선택한 날짜
  final String mealName; // 식사 이름

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
  bool _mealAdded = false; // 식사가 추가되었는지 확인하는 변수

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 히스토리에서 온 경우가 아니라면, 식단을 자동으로 추가
    if (!_mealAdded && !widget.isFromHistory) {
      Provider.of<DataManager>(context, listen: false).addMeal(
        widget.selectedDate ?? DateTime.now(),
        File(widget.imagePath),
        widget.nutrients,
        widget.mealName,
      );
      _mealAdded = true;
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
      setState(() {}); // 수정 후 UI 갱신
    });
  }

  /// ✅ 식단 삭제 기능 수정 (삭제 후 데이터 저장 추가)
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

                // ✅ 해당 날짜의 식단이 모두 삭제되었다면, 날짜 자체를 `_mealRecords`에서 제거
                if (meals.isEmpty) {
                  dataManager.allMeals.remove(mealDate);
                }

                dataManager.saveMeals(); // ✅ 삭제 후 데이터 저장
                dataManager.notifyListeners(); // ✅ UI 업데이트
              }

              Navigator.pop(context);
              _goBack(); // 삭제 후 이전 화면으로 이동
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
        _goBack(); // 뒤로 가기 버튼 클릭 시 동일한 동작 수행
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
              // 음식 이미지 표시
              Image.file(File(widget.imagePath), width: double.infinity, height: 250, fit: BoxFit.cover),
              SizedBox(height: 20),

              // 식단 이름 표시
              Text(
                "현재 등록된 식단: ${widget.mealName}",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),

              // 영양소 게이지 표시
              Expanded(
                child: ListView(
                  children: widget.nutrients.entries.map((entry) {
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
