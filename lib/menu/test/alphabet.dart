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
  // Kamera
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  bool _isCameraInitialized = false;

  // Model TFLite
  Interpreter? _interpreter;

  // Abjad soal
  final List<String> _alphabets =
      List.generate(26, (i) => String.fromCharCode(65 + i));
  String _currentAlphabet = 'A';

  //lifecycle
  @override
  void initState() {
    super.initState();
    _initCamera();
    _loadModel();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _interpreter?.close();
    super.dispose();
  }

  // init
  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    final back = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back);
    _controller =
        CameraController(back, ResolutionPreset.high, enableAudio: false);
    await _controller!.initialize();
    setState(() => _isCameraInitialized = true);
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
          'assets/model/mobilenet_v2_sibi_classification.tflite');
      debugPrint('Model loaded');
    } catch (e) {
      debugPrint('Load model error: $e');
    }
  }

  //helpers
  Float32List _imageToFloat32(img.Image im) {
    final out = Float32List(224 * 224 * 3);
    int i = 0;
    for (final p in im.data) {
      out[i++] = img.getRed(p) / 255.0;
      out[i++] = img.getGreen(p) / 255.0;
      out[i++] = img.getBlue(p) / 255.0;
    }
    return out;
  }

  // ─core
  Future<void> _takePictureAndClassify() async {
    if (!(_controller?.value.isInitialized ?? false) || _interpreter == null) {
      return;
    }

    //ambil foto
    final file = await _controller!.takePicture();
    final bytes = await file.readAsBytes();
    img.Image? ori = img.decodeImage(bytes);
    if (ori == null) return;

    //crop tengah persegi & resize 224
    final crop = min(ori.width, ori.height);
    final sx = (ori.width - crop) ~/ 2;
    final sy = (ori.height - crop) ~/ 2;
    final cropped = img.copyCrop(ori, sx, sy, crop, crop);
    final resized = img.copyResize(cropped, width: 224, height: 224);

    //normalisasi & inference
    final input =
        _imageToFloat32(resized).reshape([1, 224, 224, 3]);
    final output = List.filled(36, 0.0).reshape([1, 36]);
    _interpreter!.run(input, output);

    final scores = List<double>.from(output[0]);
    final idx = scores.indexOf(scores.reduce(max));
    final predicted =
        '0123456789abcdefghijklmnopqrstuvwxyz'[idx].toUpperCase();

    final correct = predicted == _currentAlphabet;
    _showResult(
        correct,
        correct
            ? 'Jawaban benar: $predicted'
            : 'Mohon ulangi,\nJawaban Anda $predicted');
  }

  // ─────────────────────────────────────────────────────────── UI helpers
  void _showResult(bool ok, String msg) => showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) => AlertDialog(
          backgroundColor:
              ok ? Colors.green.withOpacity(.5) : Colors.red.withOpacity(.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 80, vertical: 290),
          content: SizedBox(
            width: 100,
            child: Center(
              child: Text(msg,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            ),
          ),
        ),
      );

  void _next() {
    final i = _alphabets.indexOf(_currentAlphabet);
    if (i < _alphabets.length - 1) {
      setState(() => _currentAlphabet = _alphabets[i + 1]);
    }
  }

  void _prev() {
    final i = _alphabets.indexOf(_currentAlphabet);
    if (i > 0) {
      setState(() => _currentAlphabet = _alphabets[i - 1]);
    }
  }

  // ─────────────────────────────────────────────────────────── build
  @override
  Widget build(BuildContext ctx) {
    final w = MediaQuery.of(ctx).size.width;
    final h = MediaQuery.of(ctx).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Belajar Abjad'),
        backgroundColor: Colors.orange,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ─── soal ────────────────────────────────────────────────
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4)
                    ]),
                child: Text(_currentAlphabet,
                    style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange)),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.circular(8)),
                child: const Text('Soal',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              )
            ]),
            const SizedBox(height: 24),

            // ─── preview ─────────────────────────────────────────────
            _isCameraInitialized
                ? Container(
                    width: w * .9,
                    height: h * .5,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.black),
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CameraPreview(_controller!)),
                  )
                : SizedBox(
                    width: w * .9,
                    height: h * .5,
                    child: const Center(child: CircularProgressIndicator())),

            const SizedBox(height: 12),

            // ─── tombol capture ─────────────────────────────────────
            ElevatedButton(
              onPressed: _takePictureAndClassify,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
              child: const Text('Ambil Gambar',
                  style:
                      TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),

            const SizedBox(height: 24),

            // ─── navigasi abjad ──────────────────────────────────────
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ElevatedButton(
                  onPressed: _prev,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(12)),
                  child: const Icon(Icons.arrow_left, color: Colors.white)),
              const SizedBox(width: 16),
              ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(12)),
                  child: const Icon(Icons.arrow_right, color: Colors.white)),
            ]),
          ],
        ),
      ),
    );
  }
}
