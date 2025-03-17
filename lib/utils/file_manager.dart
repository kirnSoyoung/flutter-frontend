import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';

class FileManager {
  /// 📂 **사진을 앱 내부 저장소에 저장하는 함수**
  static Future<String?> saveImageToStorage(XFile imageFile) async {
    try {
      // 1️⃣ 앱 전용 디렉토리 가져오기
      final directory = await getApplicationDocumentsDirectory();
      final String photoDirPath = '${directory.path}/photos';

      // 2️⃣ 폴더가 없으면 생성
      final photoDir = Directory(photoDirPath);
      if (!photoDir.existsSync()) {
        photoDir.createSync(recursive: true);
      }

      // 3️⃣ 새 파일 이름 생성 (ex: meal_20240316_123456.jpg)
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = 'meal_$timestamp.jpg';
      final String filePath = '$photoDirPath/$fileName';

      // 4️⃣ 원본 이미지 파일을 새로운 경로로 복사
      final File newImage = File(filePath);
      await File(imageFile.path).copy(newImage.path);

      // 5️⃣ 저장된 이미지 경로 반환
      return newImage.path;
    } catch (e) {
      print("❌ 이미지 저장 오류: $e");
      return null;
    }
  }

  /// 🖼 **저장된 사진을 불러오는 함수**
  static Future<File?> loadImage(String filePath) async {
    try {
      final File imageFile = File(filePath);
      if (await imageFile.exists()) {
        return imageFile;
      } else {
        print("❌ 파일이 존재하지 않음: $filePath");
        return null;
      }
    } catch (e) {
      print("❌ 이미지 로드 오류: $e");
      return null;
    }
  }

  /// 🗑 **사진 삭제 함수**
  static Future<bool> deleteImage(String filePath) async {
    try {
      final File imageFile = File(filePath);
      if (await imageFile.exists()) {
        await imageFile.delete();
        return true;
      }
      return false;
    } catch (e) {
      print("❌ 이미지 삭제 오류: $e");
      return false;
    }
  }
}
