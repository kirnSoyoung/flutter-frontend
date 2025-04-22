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
import '../utils/shared_prefs.dart';
import 'nutrition_result_page.dart';

class RecognizedFood {
  final String label;
  final double confidence;
  RecognizedFood(this.label, this.confidence);
}

class DietRecognitionPage extends StatefulWidget {
  final File image;
  final DateTime? selectedDate;
  final Meal? sourceMeal;

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
  Map<String, double> servings = {};

  @override
  void initState() {
    super.initState();
    _saveMealImage(widget.image);
    _uploadAndAnalyzeImage(widget.image);
    _loadFoodList();
    _loadDefaultServing();
  }

  Future<void> _loadDefaultServing() async {
    final user = await SharedPrefs.getLoggedInUser();
    final defaultServing = user?.servingSize ?? 1.0;

    if (widget.sourceMeal != null && widget.sourceMeal!.servings.isNotEmpty) {
      servings = widget.sourceMeal!.servings;
    } else {
      servings = { for (var food in selectedFoods) food: defaultServing };
    }

    setState(() {});
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

        recognizedFoods = yoloList.map((item) {
          final label = item['label_kor'];
          return RecognizedFood(label, (item['confidence'] as num).toDouble());
        }).toList();

        selectedFoods = recognizedFoods.map((f) => f.label).toList();

        final user = await SharedPrefs.getLoggedInUser();
        final defaultServing = user?.servingSize ?? 1.0;
        servings = { for (var food in selectedFoods) food: defaultServing };
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
      print("📡 $food → API nutrients: $nutrients");

      if (nutrients != null) {
        final normalized = <String, double>{};
        nutrients.forEach((label, value) {
          final normLabel = normalizeNutrientKey(label);
          final normValue = normalizeToMg(label, value);
          normalized[normLabel] = normValue;
        });
        result[food] = normalized;
      }
    }
    return result;
  }

  Future<void> proceedToAnalysis() async {
    final dataManager = Provider.of<DataManager>(context, listen: false);
    final DateTime mealDate = widget.selectedDate ?? DateTime.now();
    if (selectedImagePath == null || selectedFoods.isEmpty) return;

    final nutrientsByFood = await fetchIndividualNutrients();

    final filteredServings = {
      for (final food in selectedFoods) food: servings[food] ?? 1.0
    };

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => NutritionResultPage(
          imagePath: selectedImagePath!,
          nutrients: nutrientsByFood,
          selectedDate: mealDate,
          mealNames: selectedFoods,
          isFromHistory: false,
          sourceMeal: null,
          servingsMap: filteredServings,
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
        .where((option) => option.contains(query) && !selectedFoods.contains(option))
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
                    final labelText = (confidence != null && confidence > 0)
                        ? "$s (${(confidence * 100).toStringAsFixed(0)}%)"
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

            Column(
              children: selectedFoods.map((label) {
                final currentServing = servings[label] ?? 1.0;
                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedFoods.remove(label);
                              servings.remove(label);
                            });
                          },
                          child: Icon(Icons.close, size: 20, color: Colors.grey),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
                          Slider(
                            value: currentServing,
                            onChanged: (value) => setState(() => servings[label] = value),
                            min: 0.5,
                            max: 5.0,
                            divisions: 9,
                            label: "${currentServing.toStringAsFixed(1)} 인분",
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
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
