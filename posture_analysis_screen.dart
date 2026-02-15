import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:path_provider/path_provider.dart';

class PostureAnalysisScreen extends StatefulWidget {
  final List<XFile> images;
  final String username;

  const PostureAnalysisScreen({
    Key? key,
    required this.images,
    required this.username,
  }) : super(key: key);

  @override
  PostureAnalysisScreenState createState() => PostureAnalysisScreenState();
}

class PostureAnalysisScreenState extends State<PostureAnalysisScreen> {
  final PoseDetector _detector = PoseDetector(options: PoseDetectorOptions());
  bool _isAnalyzing = true;
  bool _showLandmarks = false;
  late List<_AnalysisResult> _results;

  @override
  void initState() {
    super.initState();
    _runAnalysis();
  }

  Future<ui.Image> _loadUiImage(String path) async {
    final bytes = await File(path).readAsBytes();
    final comp = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, comp.complete);
    return comp.future;
  }

  Future<void> _runAnalysis() async {
    _results = [];
    for (var i = 0; i < widget.images.length; i++) {
      final file = widget.images[i];
      final uiImage = await _loadUiImage(file.path);
      final w = uiImage.width.toDouble(), h = uiImage.height.toDouble();

      final input = InputImage.fromFilePath(file.path);
      final poses = await _detector.processImage(input);

      if (poses.isEmpty) {
        _results.add(
          _AnalysisResult(
            file: file,
            issues: ['No human detected!'],
            landmarks: [],
            imageWidth: w,
            imageHeight: h,
          ),
        );
      } else {
        final pose = poses.first;
        final issues = _evaluatePosture(pose, i);
        _results.add(
          _AnalysisResult(
            file: file,
            issues: issues.isEmpty ? ['Pose normal'] : issues,
            landmarks: pose.landmarks.values.toList(),
            imageWidth: w,
            imageHeight: h,
          ),
        );
      }
    }
    setState(() => _isAnalyzing = false);
  }

  double? _rightH;
  double? _leftH;

  List<String> _evaluatePosture(Pose pose, int i) {
    final issues = <String>[];

    final rs = pose.landmarks[PoseLandmarkType.rightShoulder];
    final ls = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rh = pose.landmarks[PoseLandmarkType.rightHip];
    final lh = pose.landmarks[PoseLandmarkType.leftHip];
    final nose = pose.landmarks[PoseLandmarkType.nose];

    double _slopeAngle(PoseLandmark a, PoseLandmark b) {
      final dx = b.x - a.x;
      final dy = b.y - a.y;
      return atan2(dy, dx).abs() * 180 / pi;
    }

    double height(PoseLandmark a, PoseLandmark b) {
      final dy = b.y - a.y;
      return dy;
    }

    // Sağ yüksekliği i==1’de kaydet
    if (i == 1 && nose != null && rs != null && rh != null) {
      _rightH = height(rs, rh);
    }
    // Sol yüksekliği i==2’de kaydet
    if (i == 2 && nose != null && ls != null && lh != null) {
      _leftH = height(ls, lh);
    }
    // --- geri kalan kod aynen ---
    if (i == 0 && rs != null && ls != null) {
      final angle = _slopeAngle(rs, ls);
      issues.add('Shoulder line slope angle: ${angle.toStringAsFixed(1)}°');
      if (angle <= 2) {
        issues.add('Shoulder alignment is normal.');
      } else if (angle > 2 && angle <= 5) {
        issues.add('1st degree scoliosis (low).');
      } else if (angle > 5 && angle <= 9) {
        issues.add('2nd degree scoliosis (medium).');
      } else {
        issues.add('3rd degree scoliosis (high).');
      }
    }

    if (i == 1 && nose != null && rs != null && rh != null) {
      final a1 = _slopeAngle(nose, rs);
      final a2 = _slopeAngle(rs, rh);
      issues.add('Neck slope angle: ${a1.toStringAsFixed(1)}°');
      if (a1 <= 137) {
        issues.add('Head and neck alignment is normal.');
      } else if (a1 > 137 && a1 <= 144) {
        issues.add('1st degree kyphosis (low).');
      } else if (a1 > 144 && a1 <= 152) {
        issues.add('2nd degree kyphosis (medium).');
      } else {
        issues.add('3rd degree kyphosis (high).');
      }

      issues.add('Waist slope angle: ${a2.toStringAsFixed(1)}°');
      if (a2 <= 85) {
        issues.add('Flattening of the waist (hypolordosis).');
      } else if (a2 > 85 && a2 <= 90) {
        issues.add('Waist alignment is normal.');
      } else if (a2 > 90 && a2 <= 95) {
        issues.add('1st degree lordosis (low).');
      } else if (a2 > 95 && a2 <= 100) {
        issues.add('2nd degree lordosis (medium).');
      } else {
        issues.add('3rd degree lordosis (high).');
      }
      // artık scolioDegree burada değil; zaten 2. iterasyonda eklendi
    }

    if (i == 2 && nose != null && ls != null && lh != null) {
      final a1 = _slopeAngle(nose, ls);
      final a2 = _slopeAngle(ls, lh);
      issues.add('Neck slope angle: ${a1.toStringAsFixed(1)}°');
      if (a1 >= 43) {
        issues.add('Head and neck alignment is normal.');
      } else if (a1 < 43 && a1 >= 36) {
        issues.add('1st degree kyphosis (low).');
      } else if (a1 < 36 && a1 >= 28) {
        issues.add('2nd degree kyphosis (medium).');
      } else {
        issues.add('3rd degree kyphosis (high).');
      }

      issues.add('Waist slope angle: ${a2.toStringAsFixed(1)}°');
      if (a2 >= 95) {
        issues.add('Flattening of the waist (hypolordosis).');
      } else if (a2 < 95 && a2 >= 90) {
        issues.add('Waist alignment is normal.');
      } else if (a2 < 90 && a2 >= 85) {
        issues.add('1st degree lordosis (low).');
      } else if (a2 < 85 && a2 >= 80) {
        issues.add('2nd degree lordosis (medium).');
      } else {
        issues.add('3rd degree lordosis (high).');
      }
    }

    if (i == 3 && rs != null && ls != null) {
      final angle = _slopeAngle(rs, ls);
      issues.add('Shoulder line slope angle: ${angle.toStringAsFixed(1)}°');
      if (angle >= 178) {
        issues.add('Shoulder alignment is normal.');
      } else if (angle < 178 && angle >= 175) {
        issues.add('1st degree scoliosis (low).');
      } else if (angle < 175 && angle >= 171) {
        issues.add('2nd degree scoliosis (medium).');
      } else {
        issues.add('3rd degree scoliosis (high).');
      }
    }
    if (i == 1 && _rightH != null && _leftH != null) {
      final maxH = max(_rightH!, _leftH!);
      final minH = min(_rightH!, _leftH!);
      final percentDiff = (maxH / minH - 1) * 100;
      issues.add('diff: ${percentDiff.toStringAsFixed(1)}%');
      if (percentDiff >= 9) {
        issues.add('3rd degree scoliosis(high).');
      } else if (percentDiff >= 5) {
        issues.add('2rd degree scoliosis(medium).');
      } else if (percentDiff >= 2) {
        issues.add('1rd degree scoliosis(low).');
      } else {
        issues.add('Shoulder alignment is normal.');
      }
    }
    if (i == 2 && _rightH != null && _leftH != null) {
      final maxH = max(_rightH!, _leftH!);
      final minH = min(_rightH!, _leftH!);
      final percentDiff = (maxH / minH - 1) * 100;
      issues.add('diff: ${percentDiff.toStringAsFixed(1)}%');
      if (percentDiff >= 9) {
        issues.add('3rd degree scoliosis(high).');
      } else if (percentDiff >= 5) {
        issues.add('2rd degree scoliosis(medium).');
      } else if (percentDiff >= 2) {
        issues.add('1rd degree scoliosis(low).');
      } else {
        issues.add('Shoulder alignment is normal.');
      }
    }

    return issues;
  }

  Future<void> _exportResultsToTxt(String username) async {
    if (_isAnalyzing) return;

    final appDir = await getApplicationDocumentsDirectory();
    final userDir = Directory('${appDir.path}/users/$username');

    if (!await userDir.exists()) {
      await userDir.create(recursive: true);
    }

    final file = File('${userDir.path}/analysis_results.txt');
    final buffer = StringBuffer();

    // İstediğin sıralı etiketler
    const labels = [
      'Front angle analysis',
      'Right angle analysis',
      'Left angle analysis',
      'Back angle analysis',
    ];

    for (var i = 0; i < _results.length; i++) {
      // İndekse göre etiket seç, taşan kısım için yedek etiket
      final label = i < labels.length ? labels[i] : 'Foto ${i + 1}';
      buffer.writeln('$label:');
      for (var issue in _results[i].issues) {
        buffer.writeln('  • $issue');
      }
      buffer.writeln();
    }

    await file.writeAsString(buffer.toString());

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Analysis recorded: ${file.path}')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Photo Analysis',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 34, 36, 51),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_alt, color: Colors.white),
            onPressed: () => _exportResultsToTxt(widget.username),
          ),
          IconButton(
            icon: Icon(
              _showLandmarks ? Icons.visibility_off : Icons.visibility,
              color: Colors.white,
            ),
            onPressed: () => setState(() => _showLandmarks = !_showLandmarks),
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body:
          _isAnalyzing
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _results.length,
                itemBuilder: (ctx, i) {
                  final res = _results[i];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AspectRatio(
                        aspectRatio: res.imageWidth / res.imageHeight,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(File(res.file.path), fit: BoxFit.cover),
                            if (_showLandmarks)
                              CustomPaint(
                                painter: _LandmarkPainter(
                                  res.landmarks,
                                  res.imageWidth,
                                  res.imageHeight,
                                  i,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        color: Colors.white12,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                res.file.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              for (var issue in res.issues)
                                Text(
                                  '• $issue',
                                  style: const TextStyle(color: Colors.white),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
    );
  }
}

class _AnalysisResult {
  final XFile file;
  final List<String> issues;
  final List<PoseLandmark> landmarks;
  final double imageWidth, imageHeight;
  _AnalysisResult({
    required this.file,
    required this.issues,
    required this.landmarks,
    required this.imageWidth,
    required this.imageHeight,
  });
}

class _LandmarkPainter extends CustomPainter {
  final List<PoseLandmark> landmarks;
  final double imageW, imageH;
  final int imageIndex;

  _LandmarkPainter(this.landmarks, this.imageW, this.imageH, this.imageIndex);

  Offset _scale(PoseLandmark lm, Size size) {
    final dx = lm.x / imageW * size.width;
    final dy = lm.y / imageH * size.height;
    return Offset(dx, dy);
  }

  PoseLandmark? _get(PoseLandmarkType type) {
    try {
      return landmarks.firstWhere((lm) => lm.type == type);
    } catch (_) {
      return null;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paintA =
        Paint()
          ..color = Colors.cyan
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke;

    final paintB =
        Paint()
          ..color = Colors.orange
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke;

    final rs = _get(PoseLandmarkType.rightShoulder);
    final ls = _get(PoseLandmarkType.leftShoulder);
    final rh = _get(PoseLandmarkType.rightHip);
    final lh = _get(PoseLandmarkType.leftHip);
    final nose = _get(PoseLandmarkType.nose);

    switch (imageIndex) {
      case 0:
        if (rs != null && ls != null) {
          canvas.drawLine(_scale(rs, size), _scale(ls, size), paintA);
        }
        break;
      case 1:
        if (nose != null && rs != null) {
          canvas.drawLine(_scale(nose, size), _scale(rs, size), paintA);
        }
        if (rs != null && rh != null) {
          canvas.drawLine(_scale(rs, size), _scale(rh, size), paintB);
        }
        break;
      case 2:
        if (nose != null && ls != null) {
          canvas.drawLine(_scale(nose, size), _scale(ls, size), paintA);
        }
        if (ls != null && lh != null) {
          canvas.drawLine(_scale(ls, size), _scale(lh, size), paintB);
        }
        break;
      case 3:
        if (rs != null && ls != null) {
          canvas.drawLine(_scale(ls, size), _scale(rs, size), paintA);
        }
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _LandmarkPainter old) =>
      old.landmarks != landmarks || old.imageIndex != imageIndex;
}
