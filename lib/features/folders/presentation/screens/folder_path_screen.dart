import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class FolderPathScreen extends StatelessWidget {
  const FolderPathScreen({super.key, required this.folderPath});

  final String folderPath;

  @override
  Widget build(BuildContext context) {
    final decoded = Uri.decodeComponent(folderPath);
    final name = p.basename(decoded);
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Contents of $decoded appear once the media library is wired.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
