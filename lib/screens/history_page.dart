import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../utils/data_manager.dart';
import '../models/meal_model.dart';
import 'nutrition_result_page.dart';
import 'diet_recognition_page.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

/// 사용자가 날짜별 식단을 확인하고 새로운 식단을 추가할 수 있는 페이지
class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  DateTime _selectedDate = DateTime.now(); // 사용자가 선택한 날짜 (기본값: 오늘)

  @override
  Widget build(BuildContext context) {
    return Consumer<DataManager>(
      builder: (context, dataManager, child) {
        // 선택한 날짜의 식단 목록 가져오기
        List<Meal>? meals = dataManager.getMealsForDate(_selectedDate);

        return Scaffold(
          appBar: AppBar(title: Text("식단 기록")),
          body: Column(
            children: [
              // 날짜 선택을 위한 캘린더 위젯
              TableCalendar(
                locale: 'ko_KR',
                firstDay: DateTime(2023, 1, 1),
                lastDay: DateTime(2025, 12, 31),
                focusedDay: _selectedDate,
                selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDate = selectedDay;
                  });
                },
                headerStyle: HeaderStyle(
                  formatButtonVisible: false, // 월/주 전환 버튼 숨김
                  titleCentered: true, // 제목 중앙 정렬
                ),
              ),
              SizedBox(height: 10),

              // 선택한 날짜의 식단 목록 표시
              Expanded(
                child: meals != null && meals.isNotEmpty
                    ? ListView(
                  children: meals.map((meal) {
                    return GestureDetector(
                      onTap: () {
                        // 식단을 클릭하면 영양소 분석 결과 페이지로 이동
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NutritionResultPage(
                              imagePath: meal.image.path,
                              nutrients: meal.nutrients,
                              mealName: meal.mealName,
                              isFromHistory: true,
                              selectedDate: _selectedDate,
                            ),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          Image.file(meal.image, width: double.infinity, height: 250, fit: BoxFit.cover),
                          SizedBox(height: 5),
                          Text("사진을 클릭하여 분석 결과 보기", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    );
                  }).toList(),
                )
                    : Center(child: Text("선택한 날짜에 등록된 식단이 없습니다.")), // 식단이 없을 경우 메시지 표시
              ),
              SizedBox(height: 10),

              // 새로운 식단 추가 버튼
              ElevatedButton(
                onPressed: () async {
                  final ImagePicker picker = ImagePicker();
                  final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

                  if (pickedFile != null) {
                    File imageFile = File(pickedFile.path);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DietRecognitionPage(image: imageFile, selectedDate: _selectedDate),
                      ),
                    ).then((_) {
                      setState(() {}); // 식단 추가 후 UI 갱신
                    });
                  }
                },
                child: Text("식단 등록하기"),
              ),
              SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}
