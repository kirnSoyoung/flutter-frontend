import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/meal_model.dart';
import '../utils/file_manager.dart';
import '../utils/food_list.dart';
import '../utils/api_service.dart';
import '../utils/nutrient_utils.dart';
import '../utils/shared_prefs.dart';
import 'result_page.dart';

class RecognizedFood {
  final String label;
  final double confidence;
  RecognizedFood(this.label, this.confidence);
}

class RecognitionPage extends StatefulWidget {
  final File image;
  final DateTime? selectedDate;
  final Meal? sourceMeal;

  const RecognitionPage({
    Key? key,
    required this.image,
    this.selectedDate,
    this.sourceMeal,
  }) : super(key: key);

  @override
  State<RecognitionPage> createState() => _RecognitionPageState();
}

class _RecognitionPageState extends State<RecognitionPage> {
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
      servings = Map.from(widget.sourceMeal!.servings);
      selectedFoods = servings.keys.toList();
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

  Future<void> _addFoodFromSearch(String input) async {
    final value = input.trim();
    if (value.isEmpty) return;
    if (!selectedFoods.contains(value) && mealOptions.contains(value)) {
      final user = await SharedPrefs.getLoggedInUser(); // ✅ 사용자 정보 가져오기
      final defaultServing = user?.servingSize ?? 1.0;

      setState(() {
        selectedFoods.add(value);
        servings[value] = defaultServing;
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
      appBar: AppBar(
        title: const Text('음식 인식', style: TextStyle(color: Colors.green)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.green),
        elevation: 0,
      ),
      body: isUploading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 업로드된 이미지
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                widget.image,
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 16),

            // 검색창
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "음식 이름을 검색하세요",
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() => searchController.clear()),
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: _addFoodFromSearch,
            ),

            if (searchController.text.isNotEmpty && suggestions.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: ListView(
                  shrinkWrap: true,
                  children: suggestions.map((s) {
                    final conf = getConfidence(s);
                    final labelText = (conf != null && conf > 0)
                        ? "$s (${(conf * 100).toStringAsFixed(0)}%)"
                        : s;
                    return ListTile(
                      title: Text(labelText),
                        onTap: () async {
                          final user = await SharedPrefs.getLoggedInUser();
                          final defaultServing = user?.servingSize ?? 1.0;

                          setState(() {
                            selectedFoods.add(s);
                            servings[s] = defaultServing; // ✅ 이거 추가
                            searchController.clear();
                          });
                        }
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 20),

            // 인식된 음식별 카드 + 슬라이더
            Column(
              children: selectedFoods.map((label) {
                final currentServing = servings[label] ?? 1.0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 음식 이름 + 삭제 버튼
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(label,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedFoods.remove(label);
                                servings.remove(label);
                              });
                            },
                            child: const Icon(Icons.close, size: 20, color: Colors.grey),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // 🍚 아이콘 + 인분 수 항상 표시
                      Row(
                        children: [
                          const Icon(Icons.rice_bowl, color: Colors.green),
                          const SizedBox(width: 6),
                          Text(
                            '${currentServing.toStringAsFixed(1)} 인분',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),

                      // 커스터마이징된 초록 슬라이더
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: Colors.green,
                          inactiveTrackColor: Colors.green.withOpacity(0.3),
                          thumbColor: Colors.green,
                          overlayColor: Colors.green.withOpacity(0.15),
                          valueIndicatorColor: Colors.green,
                          showValueIndicator: ShowValueIndicator.always,
                        ),
                        child: Slider(
                          value: currentServing.clamp(0.5, 5.0),
                          min: 0.5,
                          max: 5.0,
                          divisions: 9,
                          label: '${currentServing.toStringAsFixed(1)}인분',
                          onChanged: (v) => setState(() => servings[label] = v),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // 분석 진행 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                onPressed: selectedFoods.isNotEmpty ? proceedToAnalysis : null,
                child: const Text('영양소 분석 진행'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
