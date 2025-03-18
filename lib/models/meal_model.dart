import 'dart:io';

class Meal {
  final File image;
  final Map<String, double> nutrients;
  final String mealName;

  Meal({required this.image, required this.nutrients, required this.mealName});

  Map<String, dynamic> toJson() => {
    'imagePath': image.path,
    'nutrients': nutrients,
    'mealName': mealName,
  };

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      image: File(json['imagePath']),
      nutrients: Map<String, double>.from(json['nutrients']),
      mealName: json['mealName'],
    );
  }
}
