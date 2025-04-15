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
