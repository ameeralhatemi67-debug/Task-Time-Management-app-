import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {
  // Singleton instance
  static final OCRService instance = OCRService._();
  OCRService._();

  // The ML Kit Text Recognizer (Latin script for English)
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  /// Processes an image from the provided [imagePath] and returns the extracted text.
  Future<String> recognizeText(String imagePath) async {
    try {
      // 1. Prepare the InputImage for ML Kit
      final InputImage inputImage = InputImage.fromFilePath(imagePath);

      // 2. Process the image using the ML model
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      // 3. Extract the full text string
      // ML Kit provides blocks, lines, and elements, but for our parser,
      // we just need the full raw string.
      String rawText = recognizedText.text;

      // Clean up common OCR artifacts (double spaces, weird newlines)
      return _cleanExtractedText(rawText);
    } catch (e) {
      print("OCR Service Error: $e");
      return "";
    }
  }

  /// Helper to clean text so the SmartContentParser can handle it better
  String _cleanExtractedText(String text) {
    return text
        .replaceAll('\n', ' ') // Convert newlines to spaces for linear parsing
        .replaceAll(RegExp(r'\s+'), ' ') // Remove double spaces
        .trim();
  }

  /// Always close the recognizer when done to free up resources
  void dispose() {
    _textRecognizer.close();
  }
}
