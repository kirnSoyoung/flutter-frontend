import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/meal_model.dart';
import '../utils/data_manager.dart';
import '../utils/file_manager.dart';
import '../utils/food_list.dart';
import 'nutrition_result_page.dart';

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

  /// 사진을 앱 내부 저장소에 저장하는 함수
  Future<void> _saveMealImage(File imageFile) async {
    String? savedPath = await FileManager.saveImageToStorage(XFile(imageFile.path));
    if (savedPath != null) {
      setState(() {
        selectedImagePath = savedPath;
      });
    }
  }

  /// 사진을 업로드하고, 서버에서 음식 정보를 받아오는 함수
  Future<void> _uploadAndAnalyzeImage(File image) async {
    setState(() {
      isUploading = true;
    });

    try {
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
        print("❌ 음식 인식 실패: 응답 내용이 없거나 실패 표시");
        setState(() {
          isUploading = false;
        });
      }
    } catch (e) {
      print("❌ API 요청 중 예외 발생: $e");
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

  void _clearSearch() {
    setState(() {
      searchController.clear();
      filteredMealOptions = mealOptions;
    });
  }

  void proceedToAnalysis() {
    final dataManager = Provider.of<DataManager>(context, listen: false);
    final DateTime mealDate = widget.selectedDate ?? DateTime.now();

    if (selectedImagePath == null) return;

    if (widget.isEditing) {
      List<Meal>? meals = dataManager.getMealsForDate(mealDate);

      if (meals != null) {
        meals.removeWhere((meal) =>
        File(meal.image.path).absolute.path == File(widget.image.path).absolute.path);

        if (meals.isEmpty) {
          dataManager.allMeals.remove(mealDate);
        }

        dataManager.saveMeals();
        dataManager.notifyListeners();
      }
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => NutritionResultPage(
          imagePath: selectedImagePath!,
          nutrients: nutrients,
          selectedDate: mealDate,
          mealName: selectedMeal,
          isFromHistory: false,
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
                        onChanged: _filterMeals,
                    ),

                    if (isDropdownVisible)
                      Container(
                        constraints: BoxConstraints(
                          maxHeight: (filteredMealOptions.length * 48.0).clamp(60.0, 180.0),
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
