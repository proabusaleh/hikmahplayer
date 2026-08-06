import 'package:flutter/material.dart';

class ScreenshotEditorScreen extends StatelessWidget {
  const ScreenshotEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Screenshot Editor')),
      body: const Center(child: Text('Screenshot editor')),
    );
  }
}
