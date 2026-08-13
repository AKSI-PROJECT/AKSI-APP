import 'dart:ui';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'package:flutter/foundation.dart';

enum RedactType { text, face, custom }

class RedactRegion {
  final Rect rect;
  final RedactType type;
  bool isApplied;

  RedactRegion({
    required this.rect,
    required this.type,
    this.isApplied = false,
  });
}

class MLService {
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: false,
      enableClassification: false,
    ),
  );

  Future<List<RedactRegion>> analyzeImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final List<RedactRegion> regions = [];

    try {
      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );

      final nikRegex = RegExp(r'\b\d{16}\b');
      final phoneRegex = RegExp(r'\b08\d{8,11}\b');

      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          final cleanText = line.text.replaceAll(' ', '');
          if (nikRegex.hasMatch(cleanText) || phoneRegex.hasMatch(cleanText)) {
            regions.add(
              RedactRegion(rect: line.boundingBox, type: RedactType.text),
            );
          } else if (line.text.toLowerCase().contains('tanda tangan')) {
            regions.add(
              RedactRegion(rect: line.boundingBox, type: RedactType.text),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error in OCR: $e');
      return [];
    }
    try {
      final List<Face> faces = await _faceDetector.processImage(inputImage);
      for (Face face in faces) {
        regions.add(
          RedactRegion(rect: face.boundingBox, type: RedactType.face),
        );
      }
    } catch (e) {
      debugPrint('Error in Face Detection: $e');
    }
    return regions;
  }

  void dispose() {
    _textRecognizer.close();
    _faceDetector.close();
  }
}
