import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/player/presentation/screens/mini_player.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          NavigationBar(
            selectedIndex: shell.currentIndex,
            onDestinationSelected: (i) => shell.goBranch(
              i,
              initialLocation: i == shell.currentIndex,
            ),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.movie_outlined),
                selectedIcon: Icon(Icons.movie),
                label: 'Videos',
              ),
              NavigationDestination(
                icon: Icon(Icons.music_note_outlined),
                selectedIcon: Icon(Icons.music_note),
                label: 'Music',
              ),
              NavigationDestination(
                icon: Icon(Icons.folder_outlined),
                selectedIcon: Icon(Icons.folder),
                label: 'Folders',
              ),
              NavigationDestination(
                icon: Icon(Icons.playlist_play_outlined),
                selectedIcon: Icon(Icons.playlist_play),
                label: 'Playlists',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
