import 'package:flutter/material.dart';

class ClipEditorScreen extends StatelessWidget {
  const ClipEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clip Editor')),
      body: const Center(child: Text('Clip editor')),
    );
  }
}
