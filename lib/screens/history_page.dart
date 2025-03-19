import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/data_manager.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:image_picker/image_picker.dart';
import '../screens/nutrition_result_page.dart';
import '../screens/diet_recognition_page.dart';

class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  DateTime _currentWeekStart = DateTime.now();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ko_KR');
    _currentWeekStart = _getWeekStart(DateTime.now());
    _selectedDate = DateTime.now();
  }

  /// ✅ 해당 날짜가 속한 주의 시작일 (일요일부터 시작)
  DateTime _getWeekStart(DateTime date) {
    int weekday = date.weekday;
    return date.subtract(Duration(days: weekday % 7));
  }

  /// ✅ 다음 주로 이동
  void _nextWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(Duration(days: 7));
    });
  }

  /// ✅ 이전 주로 이동
  void _previousWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.subtract(Duration(days: 7));
    });
  }

  /// ✅ 날짜 클릭 시 선택된 날짜 변경
  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);
    List<DateTime> weekDays = List.generate(
        7, (index) => _currentWeekStart.add(Duration(days: index)));

    return Scaffold(
      appBar: AppBar(title: Text("식단 기록")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ✅ 주간 네비게이션
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: _previousWeek,
                ),
                Text(
                  "< ${DateFormat.yMMMM('ko_KR').format(_currentWeekStart)} >",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward),
                  onPressed: _nextWeek,
                ),
              ],
            ),
            SizedBox(height: 10),

            // ✅ 요일 헤더 (일요일~토요일)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ["일", "월", "화", "수", "목", "금", "토"]
                  .map((day) => Text(day, style: TextStyle(fontWeight: FontWeight.bold)))
                  .toList(),
            ),
            SizedBox(height: 5),

            // ✅ 현재 주 날짜 표시 (삭제 후 초록색 점 제거)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: weekDays.map((date) {
                bool hasMeal = (dataManager.getMealsForDate(date)?.isNotEmpty ?? false);

                return GestureDetector(
                  onTap: () => _selectDate(date),
                  child: Column(
                    children: [
                      Text(
                        DateFormat.d().format(date),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _selectedDate?.day == date.day ? Colors.blue : Colors.black,
                        ),
                      ),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: hasMeal ? Colors.green : Colors.transparent, // ✅ 식단이 없으면 점 제거
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 20),

            // ✅ 현재 주에 등록된 식단 사진들 (클릭 가능 → 영양소 분석 페이지 이동)
            Expanded(
              child: ListView.builder(
                itemCount: weekDays.length,
                itemBuilder: (context, index) {
                  DateTime date = weekDays[index];
                  var meals = dataManager.getMealsForDate(date) ?? [];

                  return meals.isNotEmpty
                      ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('MM월 dd일', 'ko_KR').format(date),
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 5),
                      SizedBox(
                        height: 100,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: meals.map((meal) {
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => NutritionResultPage(
                                      imagePath: meal.image.path,
                                      nutrients: meal.nutrients,
                                      selectedDate: date,
                                      mealName: meal.mealName,
                                      isFromHistory: true,
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: EdgeInsets.only(right: 10),
                                child: Image.file(
                                  File(meal.image.path),
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      SizedBox(height: 10),
                    ],
                  )
                      : Container();
                },
              ),
            ),

            ElevatedButton(
              onPressed: () async {
                final pickedFile =
                await ImagePicker().pickImage(source: ImageSource.gallery);
                if (pickedFile != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DietRecognitionPage(
                        image: File(pickedFile.path),
                        selectedDate: _selectedDate,
                        initialMealName: "",
                        isEditing: false,
                      ),
                    ),
                  );
                }
              },
              child: Text("식단 등록하기"),
            ),
          ],
        ),
      ),
    );
  }
}
