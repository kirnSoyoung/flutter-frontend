import 'package:flutter/material.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/data_manager.dart';
import '../utils/food_list.dart';
import '../utils/file_manager.dart';
import 'nutrition_result_page.dart';
import '../models/meal_model.dart';
import 'package:http_parser/http_parser.dart';

class DietRecognitionPage extends StatefulWidget {
  final File image;
  final DateTime? selectedDate;
  final String? initialMealName;
  final bool isEditing;

  DietRecognitionPage({
    required this.image,
    this.selectedDate,
    this.initialMealName,
    this.isEditing = false,
  });

  @override
  _DietRecognitionPageState createState() => _DietRecognitionPageState();
}

class _DietRecognitionPageState extends State<DietRecognitionPage> {
  List<String> mealOptions = [];
  List<String> filteredMealOptions = [];
  List<String> recognizedFoods = [];
  Map<String, double> nutrients = {};
  late String selectedMeal;
  TextEditingController searchController = TextEditingController();
  bool isDropdownVisible = false;
  bool isUploading = true;
  final ScrollController _scrollController = ScrollController();
  String? selectedImagePath;

  @override
  void initState() {
    super.initState();
    _loadFoodList();
    _saveMealImage(widget.image);
    _uploadAndAnalyzeImage(widget.image);
  }

  /// 📂 **사진을 앱 내부 저장소에 저장하는 함수**
  void _saveMealImage(File imageFile) async {
    String? savedPath = await FileManager.saveImageToStorage(XFile(imageFile.path));
    if (savedPath != null) {
      setState(() {
        selectedImagePath = savedPath;
      });
    } else {
      print("❌ 사진 저장 실패");
    }
  }

  /// ✅ 사진을 업로드하고, 서버에서 음식 정보를 받아오는 함수
  Future<void> _uploadAndAnalyzeImage(File image) async {
    setState(() {
      isUploading = true;
    });

    var response = await FileManager.uploadImageToServer(image);

    if (response != null && response['success'] == true) {
      List<dynamic> foodList = response['recognized_foods'];

      setState(() {
        recognizedFoods = foodList.map((food) => food['food_name'] as String).toList();
        nutrients = foodList.isNotEmpty ? foodList.first['nutrients'] : {};

        if (recognizedFoods.isNotEmpty) {
          selectedMeal = recognizedFoods.first;
          searchController.text = selectedMeal;
        }

        isUploading = false;
      });
    } else {
      print("❌ 음식 인식 실패");
      setState(() {
        isUploading = false;
      });
    }
  }

  Future<void> _loadFoodList() async {
    List<String> foodList = await loadFoodList();
    setState(() {
      mealOptions = foodList;
      filteredMealOptions = foodList;

      selectedMeal = recognizedFoods.isNotEmpty
          ? recognizedFoods.first
          : (widget.initialMealName ?? mealOptions.first);

      searchController.text = selectedMeal;
      isDropdownVisible = false;
    });
  }

  void _filterMeals(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredMealOptions = mealOptions;
        isDropdownVisible = false;
      });
      return;
    }

    List<String> filteredResults = mealOptions.where((meal) => meal.contains(query)).toList();
    setState(() {
      filteredMealOptions = filteredResults;
      isDropdownVisible = filteredMealOptions.isNotEmpty;
    });
  }

  void _selectMeal(String meal) {
    setState(() {
      selectedMeal = meal;
      searchController.text = meal;
      isDropdownVisible = false;
    });
  }

  /// ✅ X 버튼 클릭 시 검색창 초기화
  void _clearSearch() {
    setState(() {
      searchController.clear();
      filteredMealOptions = mealOptions;
    });
  }

  void proceedToAnalysis() {
    final dataManager = Provider.of<DataManager>(context, listen: false);
    final DateTime mealDate = widget.selectedDate ?? DateTime.now();

    if (selectedImagePath == null) {
      print("❌ 사진 경로 없음.");
      return;
    }

    // ✅ 기존 데이터 삭제 로직 개선 (삭제 버튼과 동일한 방식 적용)
    if (widget.isEditing) {
      List<Meal>? meals = dataManager.getMealsForDate(mealDate);

      if (meals != null) {
        meals.removeWhere((meal) =>
        File(meal.image.path).absolute.path == File(widget.image.path).absolute.path); // ✅ 정확한 경로 비교

        if (meals.isEmpty) {
          dataManager.allMeals.remove(mealDate);
        }

        dataManager.saveMeals();
        dataManager.notifyListeners();
      }
    }

    // ✅ 새로운 식단 추가 후 저장
    dataManager.addMeal(mealDate, File(selectedImagePath!), nutrients, selectedMeal);
    dataManager.saveMeals();
    dataManager.notifyListeners();

    // ✅ 결과 페이지로 이동
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => NutritionResultPage(
          imagePath: selectedImagePath!,
          nutrients: nutrients,
          selectedDate: mealDate,
          mealName: selectedMeal,
          isFromHistory: true,
        ),
      ),
          (route) => route.isFirst,
    );
  }


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        setState(() {
          isDropdownVisible = false;
        });
      },
      child: Scaffold(
        appBar: AppBar(title: Text("식단 인식")),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.file(widget.image, width: double.infinity, height: 250, fit: BoxFit.cover),
              SizedBox(height: 10),

              if (isUploading)
                Center(child: CircularProgressIndicator())
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("자동 인식된 식단:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),

                    // ✅ 검색창 내부에 X 버튼 추가
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: "음식 검색",
                        border: OutlineInputBorder(),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: _clearSearch,
                        )
                            : null,
                      ),
                      onChanged: (value) {
                        _filterMeals(value);
                      },
                    ),

                    // ✅ 검색 결과 개수에 따라 자동으로 높이를 조절
                    if (isDropdownVisible)
                      Container(
                        constraints: BoxConstraints(
                          maxHeight: (filteredMealOptions.length * 48.0).clamp(60.0, 180.0), // ✅ 최소 80, 최대 180으로 조정
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: ListView(
                          controller: _scrollController,
                          children: filteredMealOptions.map((meal) {
                            return ListTile(
                              title: Text(meal),
                              onTap: () => _selectMeal(meal),
                            );
                          }).toList(),
                        ),
                      ),


                    SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: proceedToAnalysis,
                      child: Text("영양소 분석 진행"),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
