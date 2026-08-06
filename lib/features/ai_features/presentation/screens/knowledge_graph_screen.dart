import 'package:flutter/material.dart';

class KnowledgeGraphScreen extends StatelessWidget {
  const KnowledgeGraphScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Knowledge Graph')),
      body: const Center(child: Text('Knowledge graph viewer')),
    );
  }
}
