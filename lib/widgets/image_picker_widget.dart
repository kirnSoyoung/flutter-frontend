import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/file_manager.dart';
import 'dart:io';

/// 사용자가 사진을 선택할 수 있도록 하는 위젯 (카메라 또는 갤러리 사용 가능)
class ImagePickerWidget extends StatefulWidget {
  final Function(File) onImageSelected; // 이미지 선택 시 호출될 콜백 함수

  ImagePickerWidget({required this.onImageSelected});

  @override
  _ImagePickerWidgetState createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  final ImagePicker _picker = ImagePicker(); // 이미지 선택기 객체

  /// 📸 **카메라로 사진을 촬영하여 저장하는 함수**
  Future<void> pickImageFromCamera() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      await _processAndReturnImage(image);
    }
  }

  /// 🖼 **갤러리에서 사진을 선택하여 저장하는 함수**
  Future<void> pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      await _processAndReturnImage(image);
    }
  }

  /// 📂 **이미지를 저장하고 UI에 반영하는 함수**
  Future<void> _processAndReturnImage(XFile image) async {
    // 촬영한 사진을 앱 내부 저장소에 저장
    String? savedPath = await FileManager.saveImageToStorage(image);
    if (savedPath != null) {
      print("✅ 저장된 사진: $savedPath");
      widget.onImageSelected(File(savedPath)); // 선택한 사진을 부모 위젯에 전달
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => pickImageFromCamera(),
              child: Text("카메라"),
            ),
            SizedBox(width: 10),
            ElevatedButton(
              onPressed: () => pickImageFromGallery(),
              child: Text("갤러리"),
            ),
          ],
        ),
      ],
    );
  }
}
