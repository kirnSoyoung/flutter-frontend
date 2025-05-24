import '../models/meal_model.dart';

String getNutrientUnit(String label) {
  // 괄호 안의 단위를 정규표현식으로 추출
  final unitRegExp = RegExp(r'\\((.*?)\\)');
  final match = unitRegExp.firstMatch(label);

  if (match != null) {
    final rawUnit = match.group(1);

    switch (rawUnit) {
      case '㎍':
      case 'ug':
        return 'μg';
      case '㎎':
      case 'mg':
        return 'mg';
      case 'g':
        return 'g';
      case 'kcal':
        return 'kcal';
      default:
        return rawUnit ?? '';
    }
  }

  return '';
}

String normalizeNutrientKey(String label) {
  return label.split('(')[0].trim();
}

String formatNutrientValue(String label, double valueInMg) {
  final normKey = normalizeNutrientKey(label);

  if (normKey == "에너지" || normKey == "칼로리") {
    return "${valueInMg.toStringAsFixed(0)} kcal";
  }
  if (["탄수화물", "단백질", "지방", "식이섬유", "오메가 3 지방산"].contains(normKey)) {
    return "${(valueInMg / 1000).toStringAsFixed(1)} g";
  }
  if (["비타민A", "비타민B12", "엽산", "비오틴", "요오드", "셀레늄", "비타민K"].contains(normKey)) {
    return "${(valueInMg / 1000).toStringAsFixed(1)} μg";
  }

  return "${valueInMg.toStringAsFixed(1)} mg"; // 기본값
}

double normalizeToMg(String label, double value) {
  final key = normalizeNutrientKey(label);
 if (["비타민A", "비타민B12", "엽산", "비오틴", "요오드", "셀레늄", "비타민K"].contains(key)) return value / 1000;
 else return value;
  return value; // mg
}

const Map<String, List<String>> nutrientGroups = {
  "에너지": ["에너지"],
  "탄수화물/식이섬유": ["탄수화물", "식이섬유"],
  "단백질/지방": ["단백질", "지방", "오메가 3 지방산"],
  "비타민": ["비타민A", "비타민B1", "비타민B2", "비타민B6", "비타민B12", "비타민C", "비타민D", "비타민E", "비타민K", "엽산", "비오틴", "나이아신", "판토텐산"],
  "미네랄": ["칼슘", "마그네슘", "철", "아연", "구리", "망간", "요오드", "셀레늄", "인", "나트륨", "칼륨"],
};

double calculateGroupPercent({
  required Map<String, double> intake,
  required Map<String, double> rdi,
  required List<String> keys,
}) {
  final filt = keys.where((k) => intake.containsKey(k)).toList();
  if (filt.isEmpty) return 0.0;
  final sum = filt.map((k) {
    final got = intake[k]!;
    final goal = rdi[k] ?? 1.0;

    return (got / goal).clamp(0.0, 1.0);
  }).reduce((a, b) => a + b);
  return (sum / filt.length).clamp(0.0, 1.0);
}

/// 그룹별 퍼센트를 식단별로 계산한 후 평균을 내는 함수
Map<String, double> averageGroupPercentsAcrossMeals({
  required List<Meal> meals,
  required Map<String, double> rdi,
}) {
  const groupMap = {
    '에너지': ['에너지'],
    '탄수화물/식이섬유': ['탄수화물', '식이섬유'],
    '단백질/지방': ['단백질', '지방'],
    '비타민': [
      '비타민A','비타민B1','비타민B2','비타민B6','비타민B12',
      '비타민C','비타민D','비타민E','비타민K',
      '엽산','나이아신','판토텐산','비오틴'
    ],
    '미네랄': [
      '칼슘','마그네슘','철','아연','구리','망간',
      '요오드','셀레늄','인','나트륨','칼륨'
    ],
  };

  final totals = <String, double>{ for (var key in groupMap.keys) key: 0.0 };

  for (final meal in meals) {
    final summed = <String, double>{};
    meal.nutrients.forEach((_, nutrientMap) {
      nutrientMap.forEach((key, value) {
        final normalized = normalizeNutrientKey(key);
        summed[normalized] = (summed[normalized] ?? 0.0) + value;
      });
    });

    for (final entry in groupMap.entries) {
      final groupLabel = entry.key;
      final keys = entry.value;
      final percent = calculateGroupPercent(
        intake: summed,
        rdi: rdi,
        keys: keys,
      );
      totals[groupLabel] = totals[groupLabel]! + percent;
    }
  }

  return {
    for (final key in totals.keys)
      key: meals.isEmpty ? 0.0 : (totals[key]! / meals.length)
  };
}
