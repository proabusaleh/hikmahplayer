import 'package:flutter/material.dart';

class VideoDetailsScreen extends StatelessWidget {
  const VideoDetailsScreen({super.key, required this.mediaId});

  final String mediaId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Details')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline,
                size: 72, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('Media details', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Item: $mediaId',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
          ],
        ),
      ),
    );
  }
}
