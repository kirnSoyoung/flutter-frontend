/// 사용자 정보를 저장하는 클래스
class User {
  final String email; // 사용자의 이메일
  final String password; // 사용자의 비밀번호
  final String gender; // 성별 (예: 남성, 여성)
  final int age; // 나이
  final double height; // 키 (cm)
  final double weight; // 몸무게 (kg)
  final String activityLevel; // 활동 수준 (예: 낮음, 보통, 높음)

  User({
    required this.email,
    required this.password,
    required this.gender,
    required this.age,
    required this.height,
    required this.weight,
    required this.activityLevel,
  });

  /// 사용자 정보를 JSON 형식으로 변환
  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
    'gender': gender,
    'age': age,
    'height': height,
    'weight': weight,
    'activityLevel': activityLevel,
  };

  /// JSON 데이터를 `User` 객체로 변환하는 팩토리 생성자
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      email: json['email'] ?? '', // 이메일이 없을 경우 빈 문자열로 설정
      password: json['password'] ?? '',
      gender: json['gender'] ?? '남성', // 기본값: 남성
      age: (json['age'] ?? 20).toInt(), // 기본값: 20세
      height: (json['height'] ?? 170.0).toDouble(), // 기본값: 170cm
      weight: (json['weight'] ?? 60.0).toDouble(), // 기본값: 60kg
      activityLevel: json['activityLevel'] ?? '보통', // 기본값: 보통
    );
  }
}
