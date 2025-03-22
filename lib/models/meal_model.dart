import 'dart:io';

class Meal {
  final File image;
  final Map<String, double> nutrients;
  final String mealName;

  Meal({required this.image, required this.nutrients, required this.mealName});

  Map<String, dynamic> toMap() =>
      {
        "imagePath": image.path,
        "nutrients": nutrients,
        "mealName": mealName,
      };

  static Meal fromMap(Map<String, dynamic> map) {
    return Meal(
      image: File(map['imagePath']),
      nutrients: Map<String, double>.from(map['nutrients']),
      mealName: map['mealName'],
    );
  }
}