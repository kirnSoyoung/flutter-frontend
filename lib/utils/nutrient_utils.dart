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

