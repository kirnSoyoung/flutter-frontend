import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'dart:convert';

class FileManager {
  static Future<String?> saveImageToStorage(XFile imageFile) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final String photoDirPath = '${directory.path}/photos';

      final photoDir = Directory(photoDirPath);
      if (!photoDir.existsSync()) {
        photoDir.createSync(recursive: true);
      }

      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = 'meal_$timestamp.jpg';
      final String filePath = '$photoDirPath/$fileName';

      final File newImage = File(filePath);
      await File(imageFile.path).copy(newImage.path);

      return newImage.path;
    } catch (e) {
      print("❌ 이미지 저장 오류: $e");
      return null;
    }
  }

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

  static Future<Map<String, dynamic>?> uploadImageToServer(File imageFile) async {
    try {

      print("📡 [DEBUG] API 요청 보냄: http://54.253.61.191:8000/s3/upload/");
      print("📡 [DEBUG] 업로드할 파일: ${imageFile.path}");

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://54.253.61.191:8000/s3/upload/'),
      );

      var mimeType = lookupMimeType(imageFile.path);
      var fileStream = await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        contentType: mimeType != null ? MediaType.parse(mimeType) : null,
      );
      request.files.add(fileStream);

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      print("📡 [DEBUG] 서버 응답: ${response.statusCode} - ${responseData}");

      if (response.statusCode == 200) {
        print("✅ 업로드 성공: $responseData");
        return jsonDecode(responseData);
      } else {
        print("❌ 업로드 실패: ${response.reasonPhrase}");
        return null;
      }
    } catch (e) {
      print("❌ 업로드 중 오류 발생: $e");
      return null;
    }
  }
}
