import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/meal_model.dart';
import '../utils/data_manager.dart';
import '../utils/file_manager.dart';
import '../utils/food_list.dart';
import 'nutrition_result_page.dart';

class RecognizedFood {
  final String label;
  final double confidence;
  RecognizedFood(this.label, this.confidence);
}

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
  List<RecognizedFood> recognizedFoods = [];
  List<String> mealOptions = [];
  String selectedMeal = '';
  Map<String, double> nutrients = {};
  TextEditingController searchController = TextEditingController();
  String? selectedImagePath;
  bool isUploading = true;

  @override
  void initState() {
    super.initState();
    _saveMealImage(widget.image);
    _uploadAndAnalyzeImage(widget.image);
    _loadFoodList();
  }

  Future<void> _saveMealImage(File imageFile) async {
    String? savedPath = await FileManager.saveImageToStorage(XFile(imageFile.path));
    if (savedPath != null) {
      setState(() {
        selectedImagePath = savedPath;
      });
    }
  }

  Future<void> _uploadAndAnalyzeImage(File image) async {
    try {
      var response = await FileManager.uploadImageToServer(image);
      if (response != null && response['message'] == "Complete") {
        List<dynamic> foodList = response['yolo_result'];

        recognizedFoods = foodList.map((item) => RecognizedFood(
          item['label_kor'],
          (item['confidence'] as num).toDouble(),
        )).toList();

        if (recognizedFoods.isNotEmpty) {
          final top = recognizedFoods.first;
          selectedMeal = top.label;
          searchController.text = top.label;
        }
      }
    } catch (e) {
      print("❌ 업로드 또는 인식 실패: $e");
    }

    setState(() {
      isUploading = false;
    });
  }

  Future<void> _loadFoodList() async {
    mealOptions = await loadFoodList();
    setState(() {});
  }

  void _onSearchChanged(String value) {
    setState(() {});
  }

  void _onMealSelected(String label) {
    setState(() {
      selectedMeal = label;
      searchController.text = label;
    });
  }

  void _clearSearch() {
    setState(() {
      searchController.clear();
      selectedMeal = '';
    });
  }

  bool _shouldShowSuggestions() {
    final query = searchController.text.trim();
    if (query.isNotEmpty) return true;
    return selectedMeal.isEmpty;
  }

  List<Widget> _buildSuggestions() {
    final query = searchController.text.trim();

    if (query.isEmpty) {
      return recognizedFoods.map((f) {
        return ListTile(
          title: Text("${f.label} (${(f.confidence * 100).toStringAsFixed(0)}%)"),
          onTap: () => _onMealSelected(f.label),
        );
      }).toList();
    }

    final recognizedMatches = recognizedFoods
        .where((f) =>
          f.label.contains(query) &&
          f.label != selectedMeal)
        .map((f) => ListTile(
          title: Text("${f.label} (${(f.confidence * 100).toStringAsFixed(0)}%)"),
          onTap: () => _onMealSelected(f.label),
          )
        );

    final listMatches = mealOptions
        .where((m) => m.contains(query) && recognizedFoods.every((f) => f.label != m))
        .map((m) => ListTile(
      title: Text(m),
      onTap: () => _onMealSelected(m),
    ));

    return [...recognizedMatches, ...listMatches];
  }

  void proceedToAnalysis() {
    final dataManager = Provider.of<DataManager>(context, listen: false);
    final DateTime mealDate = widget.selectedDate ?? DateTime.now();

    if (selectedImagePath == null) return;

    if (widget.isEditing) {
      List<Meal>? meals = dataManager.getMealsForDate(mealDate);
      if (meals != null) {
        meals.removeWhere((meal) => File(meal.image.path).absolute.path == File(widget.image.path).absolute.path);
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
    final suggestions = _buildSuggestions();

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        setState(() {}); // 드롭다운 닫기 위함
      },
      child: Scaffold(
        appBar: AppBar(title: Text("식단 인식")),
        body: isUploading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.file(widget.image, width: double.infinity, height: 250, fit: BoxFit.cover),
              SizedBox(height: 16),

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
                onChanged: (val) {
                  _onSearchChanged(val);
                  setState(() {});
                },
              ),

              if (_shouldShowSuggestions() && suggestions.isNotEmpty)
                Container(
                  constraints: BoxConstraints(
                    maxHeight: (_buildSuggestions().length * 48.0).clamp(60.0, 200.0),
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: ListView(
                    shrinkWrap: true,
                    children: suggestions,
                  ),
                ),

              SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedMeal.isNotEmpty ? proceedToAnalysis : null,
                  child: Text("영양소 분석 진행"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
