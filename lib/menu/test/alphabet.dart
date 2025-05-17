import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class AlphabetPage extends StatefulWidget {
  const AlphabetPage({super.key});

  @override
  State<AlphabetPage> createState() => _AlphabetPageState();
}

class _AlphabetPageState extends State<AlphabetPage> {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  bool _isCameraInitialized = false;
  Interpreter? interpreter;
  FlashMode _flashMode = FlashMode.off;

  final List<String> _alphabets =
      List.generate(26, (index) => String.fromCharCode(65 + index));
  String _currentAlphabet = 'A';

  @override
  void initState() {
    super.initState();
    initializeCamera();
    loadModel();
  }

  Future<void> initializeCamera() async {
    _cameras = await availableCameras();
    final backCamera = _cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
    );

    _controller = CameraController(backCamera, ResolutionPreset.max);
    await _controller!.initialize();
    await _controller!.setFlashMode(_flashMode);

    setState(() {
      _isCameraInitialized = true;
    });
  }

  Future<void> loadModel() async {
    try {
      interpreter = await Interpreter.fromAsset(
          'assets/model/mobilenet_v2_sibi_classification.tflite');
      debugPrint('Success Load Model');
    } catch (e) {
      debugPrint("Error loading model: $e");
    }
  }

  Future<void> takePictureAndClassify() async {
    if (_controller == null || !(_controller!.value.isInitialized)) return;

    final image = await _controller!.takePicture();
    final bytes = await image.readAsBytes();

    img.Image? oriImage = img.decodeImage(bytes);
    if (oriImage == null) return;

    int w = oriImage.width;
    int h = oriImage.height;
    int cropSize = min(w, h);
    int startX = (w - cropSize) ~/ 2;
    int startY = (h - cropSize) ~/ 2;
    img.Image cropped =
        img.copyCrop(oriImage, startX, startY, cropSize, cropSize);

    img.Image resized = img.copyResize(cropped, width: 224, height: 224);

    Float32List input = Float32List(224 * 224 * 3);
    int index = 0;
    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        final pixel = resized.getPixel(x, y);
        input[index++] = img.getRed(pixel) / 255.0;
        input[index++] = img.getGreen(pixel) / 255.0;
        input[index++] = img.getBlue(pixel) / 255.0;
      }
    }

    var inputTensor = input.reshape([1, 224, 224, 3]);
    var outputTensor = List.filled(1 * 36, 0.0).reshape([1, 36]);

    interpreter?.run(inputTensor, outputTensor);

    List<double> scores = List<double>.from(outputTensor[0]);
    double maxScore = scores.reduce(max);
    int labelIndex = scores.indexOf(maxScore);

    String predictedLabel =
        '0123456789abcdefghijklmnopqrstuvwxyz'[labelIndex].toUpperCase();

    if (predictedLabel == _currentAlphabet) {
      showResultDialog(true, 'Jawaban benar: $predictedLabel');
    } else {
      showResultDialog(
          false, 'Mohon ulangi,\nJawaban Anda adalah $predictedLabel');
    }
  }

  void showResultDialog(bool isCorrect, String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        backgroundColor: isCorrect
            ? Colors.green.withOpacity(0.5)
            : Colors.red.withOpacity(0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 80, vertical: 290),
        content: SizedBox(
          width: 100,
          child: Center(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  void _showNextAlphabet() {
    final currentIndex = _alphabets.indexOf(_currentAlphabet);
    if (currentIndex < _alphabets.length - 1) {
      setState(() {
        _currentAlphabet = _alphabets[currentIndex + 1];
      });
    }
  }

  void _showPreviousAlphabet() {
    final currentIndex = _alphabets.indexOf(_currentAlphabet);
    if (currentIndex > 0) {
      setState(() {
        _currentAlphabet = _alphabets[currentIndex - 1];
      });
    }
  }

  void _toggleFlash() async {
    if (_controller == null) return;
    _flashMode = _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    await _controller!.setFlashMode(_flashMode);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(title: const Text('Belajar Abjad')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4)
                    ],
                  ),
                  child: Text(
                    _currentAlphabet,
                    style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "Soal",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                )
              ],
            ),
            const SizedBox(height: 24),
            _isCameraInitialized
                ? Container(
                    width: screenWidth * 0.9,
                    height: screenHeight * 0.5,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.black,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CameraPreview(_controller!),
                    ),
                  )
                : SizedBox(
                    width: screenWidth * 0.9,
                    height: screenHeight * 0.5,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _toggleFlash,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _flashMode == FlashMode.torch ? Colors.red : Colors.grey,
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    _flashMode == FlashMode.torch ? 'Matikan Flash' : 'Nyalakan Flash',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: takePictureAndClassify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    'Ambil Gambar',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _showPreviousAlphabet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(12),
                  ),
                  child: const Icon(Icons.arrow_left, color: Colors.white),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _showNextAlphabet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(12),
                  ),
                  child: const Icon(Icons.arrow_right, color: Colors.white),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}