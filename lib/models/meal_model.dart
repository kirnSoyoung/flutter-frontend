import 'dart:io';

class Meal {
  final File image;
  final Map<String, Map<String, double>> nutrients;
  final List<String> mealNames;
  final Map<String, double> servings;

  Meal({
    required this.image,
    required this.nutrients,
    required this.mealNames,
    required this.servings,
  });

  Map<String, dynamic> toJson() {
    return {
      'imagePath': image.path,
      'nutrients': nutrients.map((food, nutrientMap) => MapEntry(
        food,
        nutrientMap.map((k, v) => MapEntry(k, v)),
      )),
      'mealNames': mealNames,
      'servings': servings,
    };
  }

  factory Meal.fromJson(Map<String, dynamic> json) {
    final rawNutrients = Map<String, dynamic>.from(json['nutrients'] ?? {});
    final parsedNutrients = rawNutrients.map((food, nutrientMap) => MapEntry(
      food,
      Map<String, double>.from(Map<String, dynamic>.from(nutrientMap)),
    ));

    final parsedServings = Map<String, double>.from(json['servings'] ?? {});

    return Meal(
      image: File(json['imagePath']),
      nutrients: parsedNutrients,
      mealNames: List<String>.from(json['mealNames'] ?? []),
      servings: parsedServings,
    );
  }
}