import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';

class TestResult {
  const TestResult({
    required this.questionLabel,
    this.predictedLabel,
    this.accuracy,
    required this.isCorrect,
    required this.questionNumber,
  });

  final String questionLabel;
  final String? predictedLabel;
  final double? accuracy;
  final bool isCorrect;
  final int questionNumber;
}

class AlphabetPage extends StatefulWidget {
  const AlphabetPage({super.key});

  @override
  State<AlphabetPage> createState() => _AlphabetPageState();
}

class _AlphabetPageState extends State<AlphabetPage> {
  Interpreter? interpreter;
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  CameraLensDirection _currentDirection = CameraLensDirection.back;
  bool _isProcessing = false;
  int? _lastPredictionTime;
  bool _isDisposing = false;

  String? _prediction;
  double? _accuracy;

  List<String> _labels = [];
  bool _isLabelsLoaded = false;
  int _currentSoal = 0;
  List<String> _randomizedQuestions = [];
  Timer? _countdownTimer;
  int _timeLeft = 20;

  final ImagePicker _imagePicker = ImagePicker();
  File? _uploadedImage;
  bool _isUploadMode = false;

  // Store test results
  final List<TestResult> _testResults = [];
  
  // Flag to stop prediction when answer is correct or time is up
  bool _answerIsLocked = false;

  // Loading state
  bool _isInitializing = true;
  String _loadingMessage = 'Memuat aplikasi...';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      setState(() => _loadingMessage = 'Memuat daftar huruf...');
      await _loadLabels();
      
      setState(() => _loadingMessage = 'Memuat model AI...');
      await _loadModel();
      
      setState(() => _loadingMessage = 'Menyiapkan kamera...');
      await _initCamera();
      
      setState(() => _loadingMessage = 'Membuat soal...');
      _generateRandomQuestions();
      
      setState(() => _isInitializing = false);
      _startTimer();
      // Start camera stream immediately for predictions
      if (_isCameraInitialized && !_answerIsLocked) {
        _startCameraStream();
      }
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _loadingMessage = 'Error: $e';
      });
    }
  }

  Future<void> _loadLabels() async {
    try {
      final String labelsData = await rootBundle.loadString('assets/model/labels_abjad_v2.txt');
      _labels = labelsData.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      setState(() => _isLabelsLoaded = true);
    } catch (_) {
      // Fallback: Generate A-Z labels (no labels.txt needed)
      _labels = List.generate(26, (i) => String.fromCharCode(65 + i));
      setState(() => _isLabelsLoaded = true);
      debugPrint('Using fallback A-Z labels');
    }
  }

  Future<void> _loadModel() async {
    try {
      interpreter = await Interpreter.fromAsset('assets/model/model_sibi_abjad_v2.tflite');
    } catch (e) {
      debugPrint('Model error: $e');
      // Continue without model for now
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint('No cameras available');
        return;
      }

      final selectedCamera = cameras.firstWhere(
        (c) => c.lensDirection == _currentDirection,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();

      if (mounted && !_isDisposing) {
        await _cameraController!.setExposureMode(ExposureMode.auto);
        await _cameraController!.setFocusMode(FocusMode.auto);
        await _cameraController!.setFlashMode(FlashMode.off);
        
        setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      debugPrint('Camera init error: $e');
      setState(() => _isCameraInitialized = false);
    }
  }

  void _startCameraStream() {
    if (_cameraController != null && _isCameraInitialized && !_isUploadMode && !_answerIsLocked) {
      try {
        _cameraController!.startImageStream(_processCameraImage);
      } catch (e) {
        debugPrint('Error starting camera stream: $e');
      }
    }
  }

  Future<void> _flipCamera() async {
    if (_isDisposing || _isUploadMode || !_isCameraInitialized) return;
    
    // Prevent multiple flip operations
    if (_isProcessing) return;
    
    setState(() => _isProcessing = true);
    
    try {
      // Stop image stream first
      if (_cameraController?.value.isStreamingImages == true) {
        await _cameraController?.stopImageStream().timeout(
          const Duration(seconds: 2),
          onTimeout: () => debugPrint('Stop stream timeout'),
        );
      }
      
      // Dispose current controller
      await _cameraController?.dispose().timeout(
        const Duration(seconds: 2),
        onTimeout: () => debugPrint('Dispose timeout'),
      );
      _cameraController = null;
      
      setState(() {
        _isCameraInitialized = false;
        _currentDirection = _currentDirection == CameraLensDirection.back
            ? CameraLensDirection.front
            : CameraLensDirection.back;
      });
      
      // Wait a bit before reinitializing
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Reinitialize camera
      if (!_isDisposing) {
        await _initCamera();
        
        // Start camera stream again if answer is not locked
        if (_isCameraInitialized && !_answerIsLocked && !_isDisposing) {
          _startCameraStream();
        }
      }
    } catch (e) {
      debugPrint('Flip camera error: $e');
      // Try to reinitialize if flip failed
      if (!_isDisposing) {
        setState(() => _isCameraInitialized = false);
        await _initCamera();
      }
    } finally {
      if (mounted && !_isDisposing) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _startTimer() {
    _timeLeft = 20;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _stopTimer();
        _handleTimeUp();
      }
    });
  }

  void _handleTimeUp() {
    // When time is up, stop predictions and lock the answer
    setState(() {
      _answerIsLocked = true; // Stop predictions
    });
    
    // Stop camera stream
    _cameraController?.stopImageStream();
    
    // Save current question result as wrong (time up) with last prediction
    _testResults.add(TestResult(
      questionLabel: _randomizedQuestions[_currentSoal],
      predictedLabel: _prediction,
      accuracy: _accuracy,
      isCorrect: false,
      questionNumber: _currentSoal + 1,
    ));
  }

  void _stopTimer() => _countdownTimer?.cancel();
  void _resetTimer() {
    _stopTimer();
    _startTimer();
  }

  void _generateRandomQuestions() {
    _randomizedQuestions = List.from(_labels)..shuffle(Random());
  }

  void _nextSoal() {
    // Save current result if not already saved (for wrong answers when timer runs out)
    if (_prediction != null && !_testResults.any((r) => r.questionNumber == _currentSoal + 1)) {
      final isCorrect = _prediction == _randomizedQuestions[_currentSoal];
      _testResults.add(TestResult(
        questionLabel: _randomizedQuestions[_currentSoal],
        predictedLabel: _prediction,
        accuracy: _accuracy,
        isCorrect: isCorrect,
        questionNumber: _currentSoal + 1,
      ));
    }

    if (_currentSoal < _randomizedQuestions.length - 1) {
      setState(() {
        _currentSoal++;
        _prediction = null;
        _accuracy = null;
        _uploadedImage = null;
        _isUploadMode = false;
        _answerIsLocked = false; // Reset for next question
      });
      _resetTimer();
      // Start camera stream for next question
      if (_isCameraInitialized) {
        _startCameraStream();
      }
    } else {
      _showCompletionDialog();
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );
      if (file != null) {
        setState(() {
          _uploadedImage = File(file.path);
          _isUploadMode = true;
        });
        await _cameraController?.stopImageStream();
        await _processUploadedImage(_uploadedImage!);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _takePictureFromCamera() async {
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );
      if (file != null) {
        setState(() {
          _uploadedImage = File(file.path);
          _isUploadMode = true;
        });
        await _cameraController?.stopImageStream();
        await _processUploadedImage(_uploadedImage!);
      }
    } catch (e) {
      debugPrint('Error taking picture: $e');
    }
  }

  void _switchToRealTimeMode() {
    setState(() {
      _uploadedImage = null;
      _isUploadMode = false;
      _prediction = null;
      _accuracy = null;
      _answerIsLocked = false; // Allow predictions again
    });
    if (_isCameraInitialized) {
      _startCameraStream();
    }
  }

  Future<void> _processUploadedImage(File imageFile) async {
    if (interpreter == null) return;
    
    try {
      final bytes = await imageFile.readAsBytes();
      final ori = img.decodeImage(bytes);
      if (ori == null) return;
      
      final input = _preprocessImage(ori);
      final result = await _runPrediction(input);
      
      if (mounted) {
        final isCorrect = result['label'] == _randomizedQuestions[_currentSoal];
        setState(() {
          _prediction = result['label'];
          _accuracy = result['confidence'];
          _answerIsLocked = true; // Stop predictions for upload mode
        });
        
        // Stop timer if answer is correct
        if (isCorrect) {
          _stopTimer();
          
          // Save the correct result immediately
          _testResults.add(TestResult(
            questionLabel: _randomizedQuestions[_currentSoal],
            predictedLabel: _prediction!,
            accuracy: _accuracy!,
            isCorrect: true,
            questionNumber: _currentSoal + 1,
          ));
        }
      }
    } catch (e) {
      debugPrint('Error processing uploaded image: $e');
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessing || interpreter == null || !_isLabelsLoaded || _isUploadMode || _answerIsLocked) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (_lastPredictionTime != null && now - _lastPredictionTime! < 1000) return;
    _lastPredictionTime = now;

    _isProcessing = true;
    try {
      final bytes = _convertYUV420toImage(image);
      final ori = img.decodeImage(bytes);
      if (ori == null) return;
      
      final input = _preprocessImage(ori);
      final result = await _runPrediction(input);
      
      if (mounted && !_isDisposing) {
        final isCorrect = result['label'] == _randomizedQuestions[_currentSoal];
        setState(() {
          _prediction = result['label'];
          _accuracy = result['confidence'];
          
          // Stop prediction if answer is correct
          if (isCorrect) {
            _answerIsLocked = true; // Stop predictions
            _stopTimer();
            _cameraController?.stopImageStream();
            
            // Save the correct result immediately
            _testResults.add(TestResult(
              questionLabel: _randomizedQuestions[_currentSoal],
              predictedLabel: _prediction!,
              accuracy: _accuracy!,
              isCorrect: true,
              questionNumber: _currentSoal + 1,
            ));
          }
          // If incorrect, continue showing predictions until timer runs out
        });
      }
    } catch (e) {
      debugPrint('Error processing camera image: $e');
    } finally {
      _isProcessing = false;
    }
  }

  List<List<List<double>>> _preprocessImage(img.Image oriImage) {
  oriImage = img.copyResize(oriImage, width: 224, height: 224);
  oriImage = img.adjustColor(oriImage, brightness: 1.3, contrast: 1.2);
  
  return List.generate(224, (y) =>  
      List.generate(224, (x) {
        final p = oriImage.getPixel(x, y);
        return [
          p.r / 255.0,  // Ganti img.getRed(p) dengan p.r
          p.g / 255.0,  // Ganti img.getGreen(p) dengan p.g
          p.b / 255.0,  // Ganti img.getBlue(p) dengan p.b
        ];
      }),
  );
}

  Future<Map<String, dynamic>> _runPrediction(List<List<List<double>>> input) async {
    if (interpreter == null) {
      return {'label': 'ERROR', 'confidence': 0.0};
    }

    final output = List.filled(_labels.length, 0.0).reshape([1, _labels.length]);
    interpreter!.run([input], output);

    final scores = List<double>.from(output[0]);
    final labelIndex = scores.indexOf(scores.reduce(max));
    final predLabel = _labels[labelIndex];
    final confidence = scores[labelIndex];

    return {
      'label': predLabel,
      'confidence': confidence,
    };
  }

  Uint8List _convertYUV420toImage(CameraImage image) {
  // Constructor baru menggunakan named parameters
  final imgBuffer = img.Image(width: image.width, height: image.height);
  
  for (int h = 0; h < image.height; h++) {
    for (int w = 0; w < image.width; w++) {
      final uvIndex = image.planes[1].bytesPerPixel! * (w ~/ 2) +
          image.planes[1].bytesPerRow * (h ~/ 2);
      
      if (uvIndex >= 0 && uvIndex < image.planes[1].bytes.length) {
        final yp = image.planes[0].bytes[h * image.planes[0].bytesPerRow + w];
        final up = image.planes[1].bytes[uvIndex];
        final vp = image.planes[2].bytes[uvIndex];

        final y = yp.toDouble();
        final u = up.toDouble() - 128;
        final v = vp.toDouble() - 128;

        int r = (y + 1.402 * v).clamp(0, 255).toInt();
        int g = (y - 0.344 * u - 0.714 * v).clamp(0, 255).toInt();
        int b = (y + 1.772 * u).clamp(0, 255).toInt();

        // Menggunakan getPixel dan set nilai pixel
        final pixel = imgBuffer.getPixel(w, h);
        pixel.r = r;
        pixel.g = g;
        pixel.b = b;
        pixel.a = 255;
      }
    }
  }
  return Uint8List.fromList(img.encodeJpg(imgBuffer, quality: 70));
}

  void _showCompletionDialog() {
    _stopTimer();
    _cameraController?.stopImageStream();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text('Tes Selesai!', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Hasil Test Anda:',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: _testResults.map((result) {
                      final statusIcon = result.isCorrect ? '✅' : '❌';
                      final statusText = result.isCorrect ? 'BENAR' : 'SALAH';
                      final accuracyText = result.accuracy != null 
                          ? '${(result.accuracy! * 100).toStringAsFixed(1)}%' 
                          : 'N/A';
                      
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: result.isCorrect 
                              ? Colors.green.withOpacity(0.1) 
                              : Colors.red.withOpacity(0.1),
                          border: Border.all(
                            color: result.isCorrect ? Colors.green : Colors.red,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Soal ${result.questionNumber}: ${result.questionLabel}',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '$statusIcon $statusText',
                              style: GoogleFonts.poppins(
                                color: result.isCorrect ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (result.predictedLabel != null)
                              Text(
                                'Terdeteksi: ${result.predictedLabel}',
                                style: GoogleFonts.poppins(fontSize: 12),
                              ),
                            Text(
                              'Akurasi: $accuracyText',
                              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Benar: ${_testResults.where((r) => r.isCorrect).length}/${_testResults.length}',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _safeDispose();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: Text('Kembali ke Home', style: GoogleFonts.poppins()),
          )
        ],
      ),
    );
  }

  Future<void> _safeDispose() async {
    if (_isDisposing) return; // Prevent multiple dispose calls
    
    _isDisposing = true;
    
    try {
      // Stop timer first
      _stopTimer();
      
      // Stop camera stream safely
      if (_cameraController?.value.isStreamingImages == true) {
        await _cameraController?.stopImageStream().catchError((e) {
          debugPrint('Error stopping image stream: $e');
        });
      }
      
      // Dispose camera controller safely
      if (_cameraController != null) {
        await _cameraController?.dispose().catchError((e) {
          debugPrint('Error disposing camera: $e');
        });
        _cameraController = null;
      }
      
      // Close interpreter safely
      try {
        interpreter?.close();
        interpreter = null;
      } catch (e) {
        debugPrint('Error closing interpreter: $e');
      }
      
      debugPrint('Safe dispose completed');
    } catch (e) {
      debugPrint('Error in _safeDispose: $e');
    }
  }

  @override
  void dispose() {
    // Don't wait for dispose, just call it
    _safeDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true, // Allow immediate pop
      onPopInvoked: (didPop) async {
        if (didPop) {
          // Dispose in background after navigation
          _safeDispose();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FF),
        appBar: AppBar(
          title: Text('Tebak Huruf SIBI', style: GoogleFonts.poppins()),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              // Force immediate navigation without waiting for dispose
              Navigator.of(context).pop();
              // Dispose in background
              _safeDispose();
            },
          ),
          actions: [
            if (!_isInitializing) ...[
              PopupMenuButton(
                icon: const Icon(Icons.add_photo_alternate),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'gallery',
                    child: Text('Dari Galeri', style: GoogleFonts.poppins()),
                  ),
                  PopupMenuItem(
                    value: 'camera',
                    child: Text('Ambil Foto', style: GoogleFonts.poppins()),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'gallery') _pickImageFromGallery();
                  if (value == 'camera') _takePictureFromCamera();
                },
              ),
              if (!_isUploadMode && _isCameraInitialized)
                IconButton(
                  icon: const Icon(Icons.flip_camera_android),
                  onPressed: _flipCamera,
                ),
            ],
          ],
        ),
        body: _isInitializing
            ? _buildLoadingScreen()
            : !_isLabelsLoaded
                ? const Center(child: Text('Error memuat data'))
                : _buildMainContent(),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            _loadingMessage,
            style: GoogleFonts.poppins(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        _buildQuestionCard(),
        const SizedBox(height: 20),
        _buildTimerCard(),
        const SizedBox(height: 20),
        _buildImagePreview(),
        const SizedBox(height: 16),
        _buildPredictionCard(), // Compact prediction card
        const SizedBox(height: 20),
        _buildNextButton(),
        if (_isUploadMode) ...[
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _switchToRealTimeMode,
            icon: const Icon(Icons.camera_alt),
            label: Text(
              'Kembali ke Real-Time',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ],
    ),
  );

  Widget _buildQuestionCard() => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.blue.shade500,
          Colors.blue.shade700,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.blue.withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Soal ${_currentSoal + 1}/${_randomizedQuestions.length}',
            style: GoogleFonts.poppins(
              fontSize: 16, 
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tunjukkan: ${_randomizedQuestions[_currentSoal]}',
            style: GoogleFonts.poppins(
              fontSize: 28, 
              fontWeight: FontWeight.bold, 
              color: Colors.white,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildTimerCard() => Card(
    elevation: 4,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timer,
            color: _timeLeft <= 5 ? Colors.red : Colors.blue,
            size: 28,
          ),
          const SizedBox(width: 8),
          Text(
            'Waktu: $_timeLeft detik',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _timeLeft <= 5 ? Colors.red : Colors.black,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildImagePreview() => Container(
    width: 300,
    height: 300,
    decoration: BoxDecoration(
      border: Border.all(color: Colors.blue, width: 3),
      borderRadius: BorderRadius.circular(15),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: _isUploadMode && _uploadedImage != null
          ? Image.file(_uploadedImage!, fit: BoxFit.cover)
          : _isCameraInitialized
              ? CameraPreview(_cameraController!)
              : const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 10),
                      Text('Menyiapkan kamera...'),
                    ],
                  ),
                ),
    ),
  );

  Widget _buildPredictionCard() {
    // Always show prediction card, even if no prediction yet
    final displayPrediction = _prediction ?? 'Memproses...';
    final accuracyText = _accuracy != null 
        ? '${(_accuracy! * 100).toStringAsFixed(1)}%' 
        : '0.0%';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade400,
            Colors.blue.shade600,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Terdeteksi:',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayPrediction,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Akurasi',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  accuracyText,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            if (_answerIsLocked) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lock,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNextButton() => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: _nextSoal, // Always enabled
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue, // Always blue
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(
        _currentSoal < _randomizedQuestions.length - 1 ? 'Lanjut Soal' : 'Selesai',
        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
  );
}