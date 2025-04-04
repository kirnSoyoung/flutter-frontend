import 'dart:io';

class Meal {
  final File image;
  final Map<String, Map<String, double>> nutrients; // ✅ 음식별 영양소 저장 구조
  final List<String> mealNames;

  Meal({
    required this.image,
    required this.nutrients,
    required this.mealNames,
  });

  Map<String, dynamic> toJson() {
    return {
      'imagePath': image.path,
      'nutrients': nutrients.map((food, nutrientMap) => MapEntry(
        food,
        nutrientMap.map((k, v) => MapEntry(k, v)),
      )),
      'mealNames': mealNames,
    };
  }

  factory Meal.fromJson(Map<String, dynamic> json) {
    final rawNutrients = Map<String, dynamic>.from(json['nutrients'] ?? {});
    final parsedNutrients = rawNutrients.map((food, nutrientMap) => MapEntry(
      food,
      Map<String, double>.from(Map<String, dynamic>.from(nutrientMap)),
    ));

    return Meal(
      image: File(json['imagePath']),
      nutrients: parsedNutrients,
      mealNames: List<String>.from(json['mealNames'] ?? []),
    );
  }
}