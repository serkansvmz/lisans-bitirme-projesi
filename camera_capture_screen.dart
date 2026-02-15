import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:path_provider/path_provider.dart';
import 'cameras.dart';

class CameraCaptureScreen extends StatefulWidget {
  final String username;
  const CameraCaptureScreen({super.key, required this.username});

  @override
  CameraCaptureScreenState createState() => CameraCaptureScreenState();
}

class CameraCaptureScreenState extends State<CameraCaptureScreen> {
  late CameraController _controller;
  bool _isCameraInitialized = false;
  int _step = 0;
  final List<String> steps = [
    ' From the front',
    ' From the right',
    ' From the left',
    ' From the back',
  ];
  final List<XFile> _captured = [];

  final PoseDetector _detector = PoseDetector(options: PoseDetectorOptions());

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _controller = CameraController(
      cameras[0],
      ResolutionPreset.high,
      enableAudio: false,
    );
    await _controller.initialize();
    if (!mounted) return;
    setState(() => _isCameraInitialized = true);
  }

  Future<void> _captureAndAnalyze() async {
    if (!_isCameraInitialized) return;

    final img = await _controller.takePicture();

    // 1) Poz analizi
    final input = InputImage.fromFilePath(img.path);
    final poses = await _detector.processImage(input);
    if (poses.isEmpty || !_checkPose(poses.first)) {
      _showError('Pose not detected, try again!');
      return;
    }

    // 2) Kalıcı saklama
    final appDir = await getApplicationDocumentsDirectory();
    final userDir = Directory('${appDir.path}/users/${widget.username}');
    if (!await userDir.exists()) await userDir.create(recursive: true);
    final newPath =
        '${userDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(img.path).copy(newPath);
    _captured.add(XFile(newPath));

    // 3) Adımları ilerlet / tamamla
    if (_step < steps.length - 1) {
      setState(() => _step++);
      _showSuccess('Success! Now the photo: ${steps[_step]}');
    } else {
      _showSuccess('All photos taken! 🎉');
    }
  }

  bool _checkPose(Pose pose) {
    final nose = pose.landmarks[PoseLandmarkType.nose];
    final left = pose.landmarks[PoseLandmarkType.leftAnkle];
    final right = pose.landmarks[PoseLandmarkType.rightAnkle];
    if (nose == null || (left == null && right == null)) return false;
    final height = (left ?? right!)!.y - nose.y;
    if (height <= 0) return false;
    final ratio = height / 720.0;
    return ratio.between(0.55, 0.95);
  }

  void _showError(String m) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.red));
  void _showSuccess(String m) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.green));

  @override
  void dispose() {
    _detector.close();
    _controller.dispose();
    super.dispose();
  }

  Widget _overlay(String asset) => IgnorePointer(
    child: Container(
      // full-screen yapmak için:
      width: double.infinity,
      height: double.infinity,
      color: Colors.black.withOpacity(0.2),
      child: Center(
        // insan figürünün boyutu sabit kalsın:
        child: Transform.scale(
          scale: 0.75,
          child: Opacity(opacity: 0.6, child: Image.asset(asset)),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Posture Analysis:${steps[_step]}',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body:
          _isCameraInitialized
              ? Stack(
                children: [
                  CameraPreview(_controller),
                  Align(
                    alignment: const Alignment(0, .3),
                    child: _overlay(
                      'assets/images/${['front', 'right', 'left', 'back'][_step]}.jpg',
                    ),
                  ),
                ],
              )
              : const Center(child: CircularProgressIndicator()),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 30),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton(
              onPressed: _captureAndAnalyze,
              child: const Icon(Icons.camera_alt),
            ),
            if (_step == steps.length - 1) ...[
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, _captured),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(100, 50),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text('Continue'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

extension on num {
  bool between(num a, num b) => this >= a && this <= b;
}
