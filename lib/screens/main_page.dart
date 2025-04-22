// ✅ 최종 수정된 main_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/data_manager.dart';
import '../utils/nutrition_standards.dart';
import '../utils/nutrient_utils.dart';
import '../widgets/image_picker_widget.dart';
import '../widgets/nutrient_gauge.dart';
import '../widgets/box_section.dart';
import '../theme/app_theme.dart';
import 'diet_recognition_page.dart';
import 'nutrition_result_page.dart';
import '../models/meal_model.dart';

class HomePage extends StatefulWidget {
  final String email;
  HomePage(this.email);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String selectedPeriod = 'day';
  final ScrollController _scrollController = ScrollController();
  bool showFab = false;
  bool showFabOptions = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        showFab = _scrollController.offset > 300;
      });
    });
  }

  void setImage(File image) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DietRecognitionPage(image: image),
      ),
    ).then((_) => setState(() {}));
  }

  List<Meal> getMealsInRange(Map<DateTime, List<Meal>> allMeals, DateTime start, DateTime end) {
    final normStart = DateTime(start.year, start.month, start.day);
    final normEnd = DateTime(end.year, end.month, end.day);

    return allMeals.entries
        .where((entry) {
      final date = DateTime(entry.key.year, entry.key.month, entry.key.day);
      return !date.isBefore(normStart) && !date.isAfter(normEnd);
    })
        .expand((entry) => entry.value)
        .toList();
  }

  Map<String, double> sumNutrients(List<Meal> meals) {
    final total = { for (var key in averageDailyRequirements.keys) key: 0.0 };

    for (var meal in meals) {
      meal.nutrients.forEach((_, nutrientMap) {
        nutrientMap.forEach((key, value) {
          final normalized = normalizeNutrientKey(key);
          if (total.containsKey(normalized)) {
            total[normalized] = total[normalized]! + value;
          }
        });
      });
    }
    return total;
  }

  void _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source);
    if (image != null) setImage(File(image.path));
    setState(() => showFabOptions = false);
  }

  Widget _buildMiniIconButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        margin: EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Consumer<DataManager>(
            builder: (context, dataManager, child) {
              final today = DateTime.now();
              late DateTime start, end;
              if (selectedPeriod == 'day') {
                start = end = DateTime(today.year, today.month, today.day);
              } else if (selectedPeriod == 'week') {
                int weekday = today.weekday % 7;
                start = today.subtract(Duration(days: weekday));
                end = start.add(Duration(days: 5));
              } else {
                start = DateTime(today.year, today.month, 1);
                end = DateTime(today.year, today.month + 1, 0);
              }

              final meals = getMealsInRange(dataManager.allMeals, start, end);
              final intake = sumNutrients(meals);

              return CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverAppBar(
                    expandedHeight: 120,
                    floating: true,
                    pinned: true,
                    backgroundColor: Colors.white,
                    elevation: 0,
                    flexibleSpace: FlexibleSpaceBar(
                      centerTitle: true,
                      title: Text("오늘의 식단",
                        style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCameraCard(),
                          if (selectedPeriod == 'day' && meals.isNotEmpty) ...[
                            SizedBox(height: 32),
                            Text("식사 기록", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            SizedBox(height: 16),
                            SizedBox(
                              height: 120,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: meals.length,
                                itemBuilder: (context, index) {
                                  final meal = meals[index];
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => NutritionResultPage(
                                            imagePath: meal.image.path,
                                            nutrients: meal.nutrients,
                                            selectedDate: today,
                                            mealNames: meal.mealNames,
                                            isFromHistory: true,
                                            servingsMap: meal.servings,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width: 120,
                                      margin: EdgeInsets.only(right: 12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        image: DecorationImage(
                                          image: FileImage(meal.image),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                          SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: ['day', 'week', 'month'].map((period) {
                              String label = period == 'day' ? '하루' : period == 'week' ? '일주일' : '한달';
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: ElevatedButton(
                                  onPressed: () => setState(() => selectedPeriod = period),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: selectedPeriod == period ? AppTheme.primaryColor : Colors.grey[300],
                                    foregroundColor: selectedPeriod == period ? Colors.white : Colors.black87,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                  child: Text(label),
                                ),
                              );
                            }).toList(),
                          ),
                          SizedBox(height: 16),
                          Text("영양소 섭취량", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 16),
                          GroupedNutrientSection(intakeMap: intake),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          if (showFab) _buildAnimatedFabMenu(),
        ],
      ),
    );
  }

  Widget _buildCameraCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text("오늘 먹은 음식을 기록해보세요",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
          SizedBox(height: 8),
          Text("사진 한 장으로 간편하게\n영양 정보를 확인할 수 있어요",
              textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCameraButton(icon: Icons.camera_alt, label: "촬영하기", onTap: () => _pickImage(ImageSource.camera)),
              _buildCameraButton(icon: Icons.photo_library, label: "갤러리", onTap: () => _pickImage(ImageSource.gallery)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCameraButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppTheme.primaryColor),
            SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedFabMenu() {
    return Positioned(
      right: 16,
      bottom: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (showFabOptions) ...[
            _buildMiniIconButton(icon: Icons.camera_alt, color: Colors.green, onTap: () => _pickImage(ImageSource.camera)),
            SizedBox(height: 8),
            _buildMiniIconButton(icon: Icons.photo_library, color: Colors.green, onTap: () => _pickImage(ImageSource.gallery)),
            SizedBox(height: 8),
          ],
          FloatingActionButton(
            onPressed: () => setState(() => showFabOptions = !showFabOptions),
            backgroundColor: showFabOptions ? Colors.grey : AppTheme.primaryColor,
            child: Icon(showFabOptions ? Icons.close : Icons.add_a_photo, color: Colors.white),
          ),
        ],
      ),
    );
  }



}
