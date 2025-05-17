import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:google_fonts/google_fonts.dart';

class NumberPage extends StatefulWidget {
  const NumberPage({super.key});

  @override
  State<NumberPage> createState() => _NumberPageState();
}

class _NumberPageState extends State<NumberPage> {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  bool _isCameraInitialized = false;
  Interpreter? interpreter;

  final List<String> _numbers = List.generate(10, (index) => index.toString());
  String _currentNumber = '0';

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

    _controller = CameraController(backCamera, ResolutionPreset.medium);
    await _controller!.initialize();

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

    await _controller!.setFlashMode(FlashMode.off);

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

    if (predictedLabel == _currentNumber) {
      showResultDialog(true, 'Jawaban benar: $predictedLabel');
    } else {
      showResultDialog(false,
          'Mohon ulangi, \n Jawaban Anda adalah $predictedLabel');
    }
  }

  void showResultDialog(bool isCorrect, String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        backgroundColor:
            isCorrect ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 80, vertical: 290),
        content: SizedBox(
          width: 100,
          child: Center(
            child: Text(
              message,
              style: GoogleFonts.poppins(
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

  void _showNextNumber() {
    final currentIndex = _numbers.indexOf(_currentNumber);
    if (currentIndex < _numbers.length - 1) {
      setState(() {
        _currentNumber = _numbers[currentIndex + 1];
      });
    }
  }

  void _showPreviousNumber() {
    final currentIndex = _numbers.indexOf(_currentNumber);
    if (currentIndex > 0) {
      setState(() {
        _currentNumber = _numbers[currentIndex - 1];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF305CDE), Color(0xFF64A8F0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'Test Angka',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            centerTitle: false,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFB9EE1B), Color(0xFFC93737)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _currentNumber,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Soal",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 24),
            _isCameraInitialized
                ? Container(
                    width: 350,
                    height: 350,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.black,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CameraPreview(_controller!),
                    ),
                  )
                : const SizedBox(
                    width: 300,
                    height: 300,
                    child: Center(child: CircularProgressIndicator()),
                  ),
            const SizedBox(height: 12),
            SizedBox(
              width: 250,
              child: ElevatedButton(
                onPressed: takePictureAndClassify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Ambil Gambar',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _showPreviousNumber,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(12),
                  ),
                  child: const Icon(Icons.arrow_left, color: Colors.white),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _showNextNumber,
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
