import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart'; // ← Bunu ekleyin
import 'package:path/path.dart' as p;

class SavedPhotosScreen extends StatelessWidget {
  final List<XFile> savedImages;
  const SavedPhotosScreen({super.key, required this.savedImages});

  @override
  Widget build(BuildContext context) {
    if (savedImages.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Saved Photos',
            style: const TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: const Color.fromARGB(255, 34, 36, 51),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        body: const Center(
          child: Text(
            'No images saved!',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Saved Photos',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 34, 36, 51),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.black,
      body: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: savedImages.length,
        itemBuilder: (context, index) {
          final file = savedImages[index];
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(File(file.path), fit: BoxFit.cover),
          );
        },
      ),
    );
  }
}
