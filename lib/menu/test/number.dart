import 'dart:io';
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
  int _selectedCameraIndex = 0;
  bool _isProcessing = false;

  final List<String> _numbers = List.generate(10, (i) => i.toString());
  int _currentIndex = 0;
  XFile? _capturedImage;

  String? _predictedLabel;
  double? _predictionAccuracy;
  bool _isAnswered = false;

  String get _currentNumber => _numbers[_currentIndex];

  @override
  void initState() {
    super.initState();
    loadModel();
    initCameras();
  }

  Future<void> initCameras() async {
    _cameras = await availableCameras();
    if (_cameras.isNotEmpty) {
      await _initializeCamera(_selectedCameraIndex);
    }
  }

  Future<void> _initializeCamera(int index) async {
    _controller = CameraController(
      _cameras[index],
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
      interpreter = await Interpreter.fromAsset('assets/model/mobilenet_v2_sibi_num.tflite');
      debugPrint("Model loaded");
    } catch (e) {
      debugPrint("Model loading error: $e");
    }
  }

  Future<void> takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isProcessing || _controller!.value.isTakingPicture) return;

    try {
      final image = await _controller!.takePicture();
      setState(() {
        _capturedImage = image;
        _predictedLabel = null;
        _predictionAccuracy = null;
      });
      classifyCapturedImage();
    } catch (e) {
      debugPrint("Take picture error: $e");
    }
  }

  Future<void> classifyCapturedImage() async {
    if (_capturedImage == null || interpreter == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final bytes = await _capturedImage!.readAsBytes();
      img.Image? oriImage = img.decodeImage(bytes);
      if (oriImage == null) return;

      int w = oriImage.width;
      int h = oriImage.height;
      int cropSize = min(w, h);
      img.Image cropped = img.copyCrop(oriImage, (w - cropSize) ~/ 2, (h - cropSize) ~/ 2, cropSize, cropSize);

      for (int y = 0; y < cropped.height; y++) {
        for (int x = 0; x < cropped.width; x++) {
          int pixel = cropped.getPixel(x, y);
          int r = img.getRed(pixel), g = img.getGreen(pixel), b = img.getBlue(pixel);
          if (!(r > 95 && g > 40 && b > 20 &&
              max(r, max(g, b)) - min(r, min(g, b)) > 15 &&
              (r - g).abs() > 15 && r > g && r > b)) {
            cropped.setPixelRgba(x, y, 0, 0, 0);
          }
        }
      }

      img.Image resized = img.copyResize(cropped, width: 224, height: 224);
      Float32List input = Float32List(224 * 224 * 3);
      int index = 0;

      for (int y = 0; y < 224; y++) {
        for (int x = 0; x < 224; x++) {
          final p = resized.getPixel(x, y);
          input[index++] = img.getRed(p) / 255.0;
          input[index++] = img.getGreen(p) / 255.0;
          input[index++] = img.getBlue(p) / 255.0;
        }
      }

      var inputTensor = input.reshape([1, 224, 224, 3]);
      var outputTensor = List.filled(10, 0.0).reshape([1, 10]);
      interpreter?.run(inputTensor, outputTensor);

      List<double> scores = List<double>.from(outputTensor[0]);
      int labelIndex = scores.indexOf(scores.reduce(max));

      setState(() {
        _predictedLabel = labelIndex.toString();
        _predictionAccuracy = scores[labelIndex];
        _isAnswered = true;
        _isProcessing = false;
      });
    } catch (e) {
      debugPrint("Classification error: $e");
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _switchCamera() {
    if (_cameras.length > 1) {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
      _initializeCamera(_selectedCameraIndex);
    }
  }

  void _nextQuestion() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % _numbers.length;
      _capturedImage = null;
      _predictedLabel = null;
      _predictionAccuracy = null;
      _isAnswered = false;
    });
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
        title: Text('Tes Angka', style: GoogleFonts.poppins()),
        backgroundColor: const Color(0xFF305CDE),
        actions: [
          IconButton(icon: const Icon(Icons.cameraswitch), onPressed: _switchCamera),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Soal: $_currentNumber", style: GoogleFonts.poppins(fontSize: 24)),
              const SizedBox(height: 16),
              if (_capturedImage != null)
                Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: FileImage(File(_capturedImage!.path)),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else if (_isCameraInitialized)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(width: 320, height: 320, child: CameraPreview(_controller!)),
                )
              else
                const CircularProgressIndicator(),
              const SizedBox(height: 16),
              if (!_isAnswered)
                ElevatedButton(
                  onPressed: _isProcessing ? null : takePicture,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF305CDE),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: _isProcessing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('Ambil Gambar', style: GoogleFonts.poppins(color: Colors.white)),
                ),
              const SizedBox(height: 12),
              if (_predictedLabel != null && _predictionAccuracy != null)
                Column(
                  children: [
                    Text("Prediksi: $_predictedLabel", style: GoogleFonts.poppins(fontSize: 20)),
                    Text("Akurasi: ${(_predictionAccuracy! * 100).toStringAsFixed(2)}%",
                        style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey[700])),
                    const SizedBox(height: 8),
                    if (_predictedLabel == _currentNumber)
                      Text("Jawaban Benar!", style: GoogleFonts.poppins(fontSize: 18, color: Colors.green))
                    else
                      Text("Jawaban Salah", style: GoogleFonts.poppins(fontSize: 18, color: Colors.red)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _nextQuestion,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          child: Text('Lanjut Soal', style: GoogleFonts.poppins(color: Colors.white)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _capturedImage = null;
                              _predictedLabel = null;
                              _predictionAccuracy = null;
                              _isAnswered = false;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[700],
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          child: Text('Ambil Ulang Gambar', style: GoogleFonts.poppins(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
