import 'package:flutter/material.dart';

class ArtistScreen extends StatelessWidget {
  const ArtistScreen({super.key, required this.artistId});

  final String artistId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Artist')),
      body: Center(child: Text('Artist $artistId')),
    );
  }
}
