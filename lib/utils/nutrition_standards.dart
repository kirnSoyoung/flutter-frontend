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
  '에너지': 2600.0,           // kcal
  '단백질': 65000.0,          // 65g → mg
  '탄수화물': 130000.0,       // 130g → mg
  '식이섬유': 30000.0,        // 30g → mg
  '칼슘': 800.0,              // mg
  '철': 10.0,                 // mg
  '비타민A': 0.8,             // 800㎍ RAE → mg
  '비타민D': 0.01,            // 10㎍ → mg
  '비타민C': 100.0,           // mg
  '비타민B1': 1.2,            // mg
  '비타민B2': 1.5,            // mg
  '비타민B6': 1.5,            // mg
  '비타민B12': 0.0024,        // 2.4㎍ → mg
  '엽산': 0.4,                // 400㎍ DFE → mg
  '나이아신': 16.0,           // mg NE
  '판토텐산': 5.0,            // mg
  '비오틴': 0.03,             // 30㎍ → mg
  '아연': 10.0,               // mg
  '마그네슘': 350.0,          // mg
  '요오드': 0.15,             // 150㎍ → mg
  '셀레늄': 0.06,             // 60㎍ → mg
  '구리': 0.85,               // 850㎍ → mg
  '망간': 4.0,                // mg (충분섭취량)
  '칼륨': 3500.0,             // mg
  '나트륨': 1500.0,           // mg
};



const Map<String, String> nutrientUnits = {
  '에너지': '㎉',
  '탄수화물': 'g',
  '식이섬유': 'g',
  '단백질': 'g',
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

