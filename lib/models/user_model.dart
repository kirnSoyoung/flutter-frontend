/// 사용자 정보를 저장하는 클래스
class User {
  final String userId; // 서버에서 받은 사용자 식별자
  final String gender; // 성별 (예: 남성, 여성)
  final int age; // 나이
  final double height; // 키 (cm)
  final double weight; // 몸무게 (kg)
  final double activityLevel; // 활동 수준 계수 (예: 1.2, 1.5 등)
  final double servingSize; // 1회 제공량 비율

  User({
    required this.userId,
    required this.gender,
    required this.age,
    required this.height,
    required this.weight,
    required this.activityLevel,
    required this.servingSize,
  });

  /// 사용자 정보를 JSON 형식으로 변환
  Map<String, dynamic> toJson() => {
    'userId': userId,
    'gender': gender,
    'age': age,
    'height': height,
    'weight': weight,
    'activityLevel': activityLevel,
    'servingSize': servingSize,
  };

  /// JSON 데이터를 `User` 객체로 변환하는 팩토리 생성자
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'] ?? '', // 기본값: 빈 문자열
      gender: json['gender'] ?? '남성', // 기본값: 남성
      age: (json['age'] ?? 20).toInt(), // 기본값: 20세
      height: (json['height'] ?? 170.0).toDouble(), // 기본값: 170cm
      weight: (json['weight'] ?? 60.0).toDouble(), // 기본값: 60kg
      activityLevel: double.tryParse(json['activityLevel']?.toString() ?? '') ??
          activityLevelFactors[json['activityLevel']] ??
          1.5,
      servingSize: (json['servingSize'] ?? 1.0).toDouble(), // 기본값: 1.0
    );
  }

  static const Map<String, double> activityLevelFactors = {
    "낮음": 1.2,
    "보통": 1.5,
    "높음": 1.725,
    "매우 높음": 1.9,
  };

}
