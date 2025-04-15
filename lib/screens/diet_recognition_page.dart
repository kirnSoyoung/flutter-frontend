import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/meal_model.dart';
import '../utils/data_manager.dart';
import '../utils/file_manager.dart';
import '../utils/food_list.dart';
import '../utils/api_service.dart';
import '../utils/nutrient_utils.dart';
import 'nutrition_result_page.dart';

class RecognizedFood {
  final String label;
  final double confidence;
  RecognizedFood(this.label, this.confidence);
}

class DietRecognitionPage extends StatefulWidget {
  final File image;
  final DateTime? selectedDate;
  final Meal? sourceMeal; // ✅ 추가됨

  const DietRecognitionPage({
    required this.image,
    this.selectedDate,
    this.sourceMeal,
  });

  @override
  State<DietRecognitionPage> createState() => _DietRecognitionPageState();
}

class _DietRecognitionPageState extends State<DietRecognitionPage> {
  List<RecognizedFood> recognizedFoods = [];
  List<String> selectedFoods = [];
  List<String> mealOptions = [];
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

  Future<void> _loadFoodList() async {
    mealOptions = await loadFoodList();
    setState(() {});
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
      final response = await FileManager.uploadImageToServer(image);
      if (response != null && response['message'] == "Complete") {
        List<dynamic> yoloList = response['yolo_result'];

        recognizedFoods = yoloList.map((item) => RecognizedFood(
          item['label_kor'],
          (item['confidence'] as num).toDouble(),
        )).toList();

        selectedFoods = recognizedFoods.map((f) => f.label).toList();
      }
    } catch (e) {
      print("❌ 인식 실패: $e");
    }
    setState(() => isUploading = false);
  }

  Future<Map<String, Map<String, double>>> fetchIndividualNutrients() async {
    Map<String, Map<String, double>> result = {};

    for (String food in selectedFoods) {
      final nutrients = await ApiService.fetchNutrientsByName(food);
      if (nutrients != null) {
        final normalized = <String, double>{};

        nutrients.forEach((label, value) {
          final normLabel = normalizeNutrientKey(label); // label 정규화 (e.g. "비타민C (mg)" → "비타민C")
          final normValue = normalizeToMg(label, value); // value 정규화 (e.g. 1000000 → 100)
          normalized[normLabel] = normValue;
        });

        result[food] = normalized; // ✅ 여기서부터는 정규화된 key/value만 사용!
      }
    }
    return result;
  }


  Future<void> proceedToAnalysis() async {
    final dataManager = Provider.of<DataManager>(context, listen: false);
    final DateTime mealDate = widget.selectedDate ?? DateTime.now();
    if (selectedImagePath == null || selectedFoods.isEmpty) return;

    final nutrientsByFood = await fetchIndividualNutrients();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => NutritionResultPage(
          imagePath: selectedImagePath!,
          nutrients: nutrientsByFood,
          selectedDate: mealDate,
          mealNames: selectedFoods,
          isFromHistory: false,
          sourceMeal: widget.sourceMeal, // ✅ 전달됨!
        ),
      ),
          (route) => route.isFirst,
    );
  }

  void _addFoodFromSearch(String input) {
    if (input.trim().isEmpty) return;
    final value = input.trim();
    if (!selectedFoods.contains(value) && mealOptions.contains(value)) {
      setState(() {
        selectedFoods.add(value);
        searchController.clear();
      });
    }
  }

  List<String> getFilteredSuggestions(String query) {
    return mealOptions
        .where((option) =>
    option.contains(query) && !selectedFoods.contains(option))
        .toList();
  }

  double? getConfidence(String label) {
    return recognizedFoods.firstWhere(
          (f) => f.label == label,
      orElse: () => RecognizedFood(label, -1),
    ).confidence;
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = getFilteredSuggestions(searchController.text);

    return Scaffold(
      appBar: AppBar(title: Text("식단 인식")),
      body: isUploading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.file(widget.image, width: double.infinity, height: 250, fit: BoxFit.cover),
            SizedBox(height: 16),
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "음식 이름을 검색하세요",
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () => setState(() => searchController.clear()),
                )
                    : null,
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: _addFoodFromSearch,
            ),
            if (searchController.text.isNotEmpty && suggestions.isNotEmpty)
              Container(
                constraints: BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ListView(
                  shrinkWrap: true,
                  children: suggestions.map((s) {
                    final confidence = getConfidence(s);
                    final labelText = confidence != null && confidence > 0
                        ? "$s (\${(confidence * 100).toStringAsFixed(0)}%)"
                        : s;
                    return ListTile(
                      title: Text(labelText),
                      onTap: () {
                        setState(() {
                          selectedFoods.add(s);
                          searchController.clear();
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: selectedFoods.map((label) => Chip(
                label: Text(label),
                deleteIcon: Icon(Icons.close),
                onDeleted: () => setState(() => selectedFoods.remove(label)),
              )).toList(),
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedFoods.isNotEmpty ? proceedToAnalysis : null,
                child: Text("영양소 분석 진행"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
