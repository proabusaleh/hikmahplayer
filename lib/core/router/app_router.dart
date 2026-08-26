import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../presentation/screens/favorites/favorites_screen.dart';
import '../../presentation/screens/history/history_screen.dart';
import '../../presentation/screens/home/folders/folders_screen.dart';
import '../../presentation/screens/home/music/music_screen.dart';
import '../../presentation/screens/home/playlists/playlists_screen.dart';
import '../../presentation/screens/home/videos/videos_screen.dart';
import '../../presentation/screens/search/search_screen.dart';
import 'route_names.dart';

final appRouterProvider = Provider<NavigatorObserver>((ref) {
  return NavigatorObserver();
});

class AppRouter {
  AppRouter._();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.videos:
        return MaterialPageRoute(builder: (_) => const VideosScreen());
      case RouteNames.music:
        return MaterialPageRoute(builder: (_) => const MusicScreen());
      case RouteNames.folders:
        return MaterialPageRoute(builder: (_) => const FoldersScreen());
      case RouteNames.playlists:
        return MaterialPageRoute(builder: (_) => const PlaylistsScreen());
      case RouteNames.search:
        return MaterialPageRoute(builder: (_) => const SearchScreen());
      case RouteNames.favorites:
        return MaterialPageRoute(builder: (_) => const FavoritesScreen());
      case RouteNames.history:
        return MaterialPageRoute(builder: (_) => const HistoryScreen());
      case RouteNames.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
