import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class UserImagesScreen extends StatelessWidget {
  final Directory folder;
  const UserImagesScreen({super.key, required this.folder});

  @override
  Widget build(BuildContext context) {
    final files =
        folder
            .listSync()
            .where((e) {
              final l = e.path.toLowerCase();
              return l.endsWith('.jpg') ||
                  l.endsWith('.png') ||
                  l.endsWith('.jpeg');
            })
            .cast<File>()
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          p.basename(folder.path),
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 34, 36, 51),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.black,
      body:
          files.isEmpty
              ? const Center(
                child: Text(
                  'No images!',
                  style: TextStyle(color: Colors.white),
                ),
              )
              : GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: files.length,
                itemBuilder:
                    (_, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(files[i], fit: BoxFit.cover),
                    ),
              ),
    );
  }
}
