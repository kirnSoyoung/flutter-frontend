import 'package:flutter/material.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/data_manager.dart';
import '../utils/food_list.dart'; // 음식 리스트 가져오기
import '../utils/test_nutrients.dart';
import '../utils/file_manager.dart';
import 'nutrition_result_page.dart';

/// 사용자가 식단을 선택하고 영양소 분석을 진행하는 페이지
class DietRecognitionPage extends StatefulWidget {
  final File image; // 선택한 음식 이미지
  final DateTime? selectedDate; // 사용자가 선택한 날짜 (기본값: 오늘 날짜)
  final String? initialMealName; // 기존 식단 이름 (수정 시 사용)
  final bool isEditing; // 수정 여부 (기본값: false)

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
  List<String> mealOptions = []; // 전체 음식 리스트
  List<String> filteredMealOptions = []; // 검색된 음식 리스트
  late String selectedMeal; // 선택한 식단
  TextEditingController searchController = TextEditingController(); // 검색어 입력 필드
  bool isDropdownVisible = false; // 드롭다운 표시 여부
  final ScrollController _scrollController = ScrollController(); // 스크롤 컨트롤러
  String? selectedImagePath;

  @override
  void initState() {
    super.initState();
    _loadFoodList(); // 저장된 음식 리스트 불러오기

    // 검색어 입력 시 자동 필터링
    searchController.addListener(() {
      _filterMeals(searchController.text);
    });

    // 사용자가 등록한 사진을 저장소에 저장
    _saveMealImage(widget.image);
  }

  /// 📂 **사진을 앱 내부 저장소에 저장하는 함수**
  void _saveMealImage(File imageFile) async {
    String? savedPath = await FileManager.saveImageToStorage(XFile(imageFile.path));
    if (savedPath != null) {
      print("✅ 저장된 사진 경로: $savedPath");
      setState(() {
        selectedImagePath = savedPath; // 저장된 경로를 UI에서 사용하도록 설정
      });
    } else {
      print("❌ 사진 저장 실패");
    }
  }

  /// 음식 리스트를 SharedPreferences에서 불러오는 함수
  Future<void> _loadFoodList() async {
    List<String> foodList = await loadFoodList();
    setState(() {
      mealOptions = foodList;
      filteredMealOptions = foodList; // 처음에는 전체 리스트 표시
      selectedMeal = mealOptions.contains(widget.initialMealName)
          ? widget.initialMealName!
          : mealOptions.first;
      searchController.text = selectedMeal; // 기본값을 검색 필드에 설정
      isDropdownVisible = false; // 앱 실행 시 드롭다운 닫힌 상태 유지
    });
  }

  /// 검색 기능: 입력값과 일치하는 음식만 표시 (렉 방지)
  void _filterMeals(String query) {
    if (query.isEmpty) {
      // 검색어가 비어 있으면 모든 리스트를 그대로 표시 & 드롭다운 닫음
      setState(() {
        filteredMealOptions = mealOptions;
        isDropdownVisible = false;
      });
      return;
    }

    // 기존 필터링 방식 유지
    List<String> filteredResults = mealOptions.where((meal) => meal.contains(query)).toList();

    // 변경 사항이 있을 때만 setState 호출 (불필요한 UI 업데이트 방지)
    if (mounted && (filteredMealOptions != filteredResults || !isDropdownVisible)) {
      setState(() {
        filteredMealOptions = filteredResults;
        isDropdownVisible = filteredMealOptions.isNotEmpty;
      });
    }
  }


  /// 사용자가 음식 리스트에서 선택한 경우
  void _selectMeal(String meal) {
    setState(() {
      selectedMeal = meal;
      searchController.text = meal; // 검색창 업데이트
      isDropdownVisible = false; // 선택 후 드롭다운 숨김
    });
  }

  /// 영양소 분석 결과 페이지로 이동
  void proceedToAnalysis() {
    final dataManager = Provider.of<DataManager>(context, listen: false);
    final DateTime mealDate = widget.selectedDate ?? DateTime.now();

    // 저장된 사진 경로를 사용
    if (selectedImagePath == null) {
      print("❌ 사진 경로 없음. 저장된 사진을 찾을 수 없음.");
      return;
    }

    // 기존 식단 수정 시 기존 데이터 삭제 후 업데이트
    dataManager.getMealsForDate(mealDate)
        ?.removeWhere((meal) => widget.isEditing && meal.image.path == widget.image.path);

    // 저장된 사진 경로를 사용하여 데이터 저장
    dataManager.addMeal(mealDate, File(selectedImagePath!), testNutrients, selectedMeal);

    // 영양소 분석 결과 페이지로 이동 (이전 화면 제거)
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => NutritionResultPage(
          imagePath: widget.image.path,
          nutrients: testNutrients,
          selectedDate: mealDate,
          mealName: selectedMeal,
          isFromHistory: true,
        ),
      ),
          (route) => route.isFirst, // 첫 화면(Home)만 남기고 모든 화면 제거
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 화면 아무 곳이나 터치하면 키보드 닫힘
        FocusScope.of(context).unfocus();
        setState(() {
          isDropdownVisible = false; // 키보드가 닫힐 때 드롭다운도 닫힘
        });
      },
      child: Scaffold(
        appBar: AppBar(title: Text("식단 인식")),
        body: SingleChildScrollView( // 키보드가 뜰 때 Bottom Overflow 방지
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 사용자가 선택한 음식 이미지 표시 (기기 저장소에서 불러오기)
                selectedImagePath != null
                    ? Image.file(File(selectedImagePath!), width: double.infinity, height: 250, fit: BoxFit.cover)
                    : Image.file(widget.image, width: double.infinity, height: 250, fit: BoxFit.cover),

                // 자동 인식된 식단 텍스트
                Text("자동 인식된 식단:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),

                // 검색창 + 드롭다운 버튼
                GestureDetector(
                  onTap: () {
                    setState(() {
                      isDropdownVisible = !isDropdownVisible;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: searchController,
                            decoration: InputDecoration(
                              hintText: "음식 검색",
                              border: InputBorder.none,
                            ),
                            onChanged: (value) {
                              _filterMeals(value);
                            },
                          ),
                        ),
                        Icon(Icons.arrow_drop_down, color: Colors.grey), // 드롭다운 버튼
                      ],
                    ),
                  ),
                ),

                // 드롭다운 리스트 (검색 결과) - 검색된 개수에 맞춰 높이 조절
                if (isDropdownVisible && filteredMealOptions.isNotEmpty)
                  Container(
                    constraints: BoxConstraints(
                      maxHeight: 200, // 최대 높이 제한
                      minHeight: (filteredMealOptions.length * 48.0).clamp(48.0, 200.0), // 최소 높이 보정
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        child: Column(
                          children: filteredMealOptions.map((meal) {
                            return ListTile(
                              title: Text(meal),
                              onTap: () {
                                _selectMeal(meal);
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),

                SizedBox(height: 20),

                // 영양소 분석 진행 버튼
                ElevatedButton(
                  onPressed: proceedToAnalysis,
                  child: Text("영양소 분석 진행"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
