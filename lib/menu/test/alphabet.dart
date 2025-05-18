import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:google_fonts/google_fonts.dart';

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
  int _selectedCameraIndex = 0;

  final List<String> _alphabets =
      List.generate(26, (index) => String.fromCharCode(65 + index));
  int _currentIndex = 0;
  int _score = 0;

  String get _currentAlphabet => _alphabets[_currentIndex];

  @override
  void initState() {
    super.initState();
    loadModel();
    initCameras();
  }

  Future<void> initCameras() async {
    _cameras = await availableCameras();
    if (_cameras.isNotEmpty) {
      _initializeCamera(_selectedCameraIndex);
    }
  }

  Future<void> _initializeCamera(int cameraIndex) async {
    _controller = CameraController(
      _cameras[cameraIndex],
      ResolutionPreset.ultraHigh,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
    } catch (e) {
      debugPrint("Camera init error: $e");
    }

    setState(() {
      _isCameraInitialized = true;
    });
  }

  Future<void> loadModel() async {
    try {
      interpreter = await Interpreter.fromAsset(
        'assets/model/mobilenet_v2_sibi_classification.tflite',
      );
      debugPrint('Model loaded');
    } catch (e) {
      debugPrint("Error loading model: $e");
    }
  }

  Future<void> takePictureAndClassify() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

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
      // Deteksi warna kulit (sederhana) dan blok warna lain jadi hitam
  for (int y = 0; y < cropped.height; y++) {
    for (int x = 0; x < cropped.width; x++) {
      int pixel = cropped.getPixel(x, y);
      int r = img.getRed(pixel);
      int g = img.getGreen(pixel);
      int b = img.getBlue(pixel);

      // Range sederhana untuk warna kulit (bisa dituning)
      if (!(r > 95 && g > 40 && b > 20 &&
            max(r, max(g, b)) - min(r, min(g, b)) > 15 &&
            (r - g).abs() > 15 && r > g && r > b)) {
        cropped.setPixelRgba(x, y, 0, 0, 0); // Ubah jadi hitam
      }
    }
  }
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
    int labelIndex = scores.indexOf(scores.reduce(max));
    String predictedLabel =
        'abcdefghijklmnopqrstuvwxyz'[labelIndex].toUpperCase();

    bool isCorrect = predictedLabel == _currentAlphabet;
    if (isCorrect) _score++;

    showResultDialog(isCorrect, predictedLabel);
  }

  void showResultDialog(bool isCorrect, String predictedLabel) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor:
            isCorrect ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 80, vertical: 280),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isCorrect
                  ? 'Benar! $predictedLabel'
                  : 'Salah! Anda menjawab $predictedLabel',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _goToNextAlphabet();
              },
              child: const Text("Lanjut"),
            )
          ],
        ),
      ),
    );
  }

  void _goToNextAlphabet() {
    if (_currentIndex < _alphabets.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      _showFinalScore();
    }
  }

  void _showFinalScore() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Tes Selesai"),
        content: Text(
          "Skor Anda: $_score / ${_alphabets.length}",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _currentIndex = 0;
                _score = 0;
              });
            },
            child: const Text("Ulangi"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Kembali"),
          ),
        ],
      ),
    );
  }

  void _switchCamera() {
    if (_cameras.length > 1) {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
      _initializeCamera(_selectedCameraIndex);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Abjad', style: GoogleFonts.poppins()),
        backgroundColor: const Color(0xFF305CDE),
        actions: [
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: _switchCamera,
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Soal: $_currentAlphabet", style: GoogleFonts.poppins(fontSize: 24)),
            const SizedBox(height: 16),
            _isCameraInitialized
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 320,
                      height: 320,
                      child: CameraPreview(_controller!),
                    ),
                  )
                : const CircularProgressIndicator(),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: takePictureAndClassify,
              child: Text('Ambil Gambar', style: GoogleFonts.poppins()),
            ),
            const SizedBox(height: 8),
            Text("Skor: $_score", style: GoogleFonts.poppins(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
