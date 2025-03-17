import 'dart:io';

/// 한 끼 식사의 정보를 저장하는 클래스
class Meal {
  final File image; // 식사 이미지 파일
  final Map<String, double> nutrients; // 영양소 정보 (키: 영양소 이름, 값: 해당 영양소의 함량)
  final String mealName; // 식사 이름 (예: 김치찌개, 비빔밥 등)

  Meal({required this.image, required this.nutrients, required this.mealName});
}
