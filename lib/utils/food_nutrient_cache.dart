class FoodNutrientCache {
  static final Map<String, Map<String, double>> _cache = {};

  static Map<String, double>? get(String foodName) => _cache[foodName];

  static void save(String foodName, Map<String, double> nutrients) {
    _cache[foodName] = nutrients;
  }
}
