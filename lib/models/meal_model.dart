// 📄 meal_model.dart (식단 단위로 리팩터링)
import 'dart:io';

class Meal {
  final File image;
  final Map<String, double> nutrients;
  final List<String> mealNames; // ✅ 여러 음식으로 변경

  Meal({
    required this.image,
    required this.nutrients,
    required this.mealNames,
  });

  Map<String, dynamic> toJson() => {
    'imagePath': image.path,
    'nutrients': nutrients,
    'mealNames': mealNames,
  };

  static Meal fromJson(Map<String, dynamic> json) {
    return Meal(
      image: File(json['imagePath']),
      nutrients: Map<String, double>.from(json['nutrients']),
      mealNames: List<String>.from(json['mealNames']),
    );
  }
}