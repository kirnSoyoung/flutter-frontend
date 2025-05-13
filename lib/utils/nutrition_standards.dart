import '../models/user_model.dart';

Map<String, double> calculatePersonalRequirements(User user) {
  double bmr;
  if (user.gender == "남성") {
    bmr = 10 * user.weight + 6.25 * user.height - 5 * user.age + 5;
  } else {
    bmr = 10 * user.weight + 6.25 * user.height - 5 * user.age - 161;
  }

  double activityFactor = 1.2;
  if (user.activityLevel == "보통") activityFactor = 1.5;
  else if (user.activityLevel == "높음") activityFactor = 1.725;
  else if (user.activityLevel == "매우 높음") activityFactor = 1.9;

  final tdee = bmr * activityFactor;
  final rdiCalories = koreanMale19to29RDI["에너지"] ?? 2600.0;
  final calorieRatio = tdee / rdiCalories;

  return koreanMale19to29RDI.map((key, value) {
    return MapEntry(key, key == "에너지" ? tdee.roundToDouble() : value * calorieRatio);
  });
}


const Map<String, double> koreanMale19to29RDI = {
  '에너지': 2600.0,
  '단백질': 65000.0,
  '지방': 58000.0,
  '탄수화물': 324000.0,
  '식이섬유': 25000.0,
  '칼슘': 800.0,
  '철': 10.0,
  '비타민A': 0.75,        // 750μg → 0.75mg
  '비타민D': 0.01,        // 10μg → 0.01mg
  '비타민C': 100.0,
  '비타민B1': 1.5,
  '비타민B2': 1.7,
  '비타민B6': 1.6,
  '비타민B12': 0.0024,     // 2.4μg → 0.0024mg
  '엽산': 0.4,            // 400μg → 0.4mg
  '나이아신': 16.0,
  '판토텐산': 5.0,
  '비오틴': 0.03,         // 30μg → 0.03mg
  '아연': 10.0,
  '마그네슘': 350.0,
  '요오드': 0.15,         // 150μg → 0.15mg
  '셀레늄': 0.055,        // 55μg → 0.055mg
  '구리': 0.9,
  '망간': 2.3,
  '칼륨': 3500.0,
  '나트륨': 1500.0,
};


const Map<String, String> nutrientUnits = {
  '에너지': '㎉',
  '탄수화물': 'g',
  '식이섬유': 'g',
  '단백질': 'g',
  '지방': 'g',
  '오메가 3 지방산': 'g',
  '비타민A': '㎍',
  '비타민D': '㎍',
  '비타민E': '㎎',
  '비타민K': '㎍',
  '비타민C': '㎎',
  '비타민B1': '㎎',
  '비타민B2': '㎎',
  '나이아신': '㎎',
  '비타민B6': '㎎',
  '비타민B12': '㎍',
  '엽산': '㎍',
  '판토텐산': '㎎',
  '비오틴': '㎍',
  '칼슘': '㎎',
  '마그네슘': '㎎',
  '철': '㎎',
  '아연': '㎎',
  '구리': '㎎',
  '망간': '㎎',
  '요오드': '㎍',
  '셀레늄': '㎍',
  '인': '㎎',
  '나트륨': '㎎',
  '칼륨': '㎎',
};

