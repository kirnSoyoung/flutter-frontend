import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../utils/file_manager.dart';

class ImagePickerWidget extends StatefulWidget {
  final Function(File) onImageSelected;

  ImagePickerWidget({required this.onImageSelected});

  @override
  _ImagePickerWidgetState createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  final ImagePicker _picker = ImagePicker();

  Future<void> pickImageFromCamera() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      await _processAndReturnImage(image);
    }
  }

  Future<void> pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      await _processAndReturnImage(image);
    }
  }

  Future<void> _processAndReturnImage(XFile image) async {
    final savedPath = await FileManager.saveImageToStorage(image);
    if (savedPath != null) {
      widget.onImageSelected(File(savedPath));
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
