import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/player/presentation/screens/audio_player_screen.dart';
import '../../features/player/presentation/screens/video_player_screen.dart';
import '../../features/search/presentation/screens/favorites_screen.dart';
import '../../features/search/presentation/screens/history_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/settings/presentation/screens/about_screen.dart';
import '../../features/settings/presentation/screens/playback_settings_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/screens/storage_settings_screen.dart';
import '../../features/settings/presentation/screens/theme_settings_screen.dart';
import '../../features/splash/presentation/screens/scanning_screen.dart';
import '../../features/analytics/presentation/screens/statistics_screen.dart';
import '../../features/storage/presentation/screens/storage_manager_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../presentation/screens/home/folders/folder_manager_screen.dart';
import '../../presentation/screens/home/me/me_tab.dart';
import '../../presentation/screens/home/home_tab.dart';
import '../../presentation/screens/home/music/music_tab.dart';
import '../../presentation/screens/home/video/video_tab.dart';
import '../../shared/shell/home_shell.dart';
import '../storage/prefs_service.dart';
import 'route_names.dart';

GoRouter createAppRouter({required PrefsService prefs}) {
  return GoRouter(
    initialLocation: RouteNames.splash,
    redirect: (context, state) {
      final onboarded = prefs.onboardingCompleted;
      final location = state.matchedLocation;
      const guarded = [
        RouteNames.splash,
        RouteNames.onboarding,
        '/scanning',
      ];
      if (!onboarded && !guarded.contains(location)) {
        return RouteNames.splash;
      }
      if (onboarded && location == RouteNames.onboarding) {
        return RouteNames.home;
      }
      return null;
    },
    routes: [
      // ─── Splash & onboarding ───
      GoRoute(
        path: RouteNames.splash,
        builder: (_, _) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/scanning',
        builder: (_, _) => const ScanningScreen(),
      ),

      // ─── Home shell (4 tabs) ───
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            path: RouteNames.home,
            pageBuilder: (_, _) => const NoTransitionPage(child: HomeTab()),
          ),
          GoRoute(
            path: RouteNames.video,
            pageBuilder: (_, _) => const NoTransitionPage(child: VideoTab()),
          ),
          GoRoute(
            path: RouteNames.music,
            pageBuilder: (_, _) => const NoTransitionPage(child: MusicTab()),
          ),
          GoRoute(
            path: RouteNames.me,
            pageBuilder: (_, _) => const NoTransitionPage(child: MeTab()),
          ),
        ],
      ),

      // ─── Overlay screens ───
      GoRoute(
        path: RouteNames.search,
        builder: (_, _) => const SearchScreen(),
      ),
      GoRoute(
        path: RouteNames.favorites,
        builder: (_, _) => const FavoritesScreen(),
      ),
      GoRoute(
        path: RouteNames.history,
        builder: (_, _) => const HistoryScreen(),
      ),
      GoRoute(
        path: RouteNames.folderManager,
        builder: (_, _) => const FolderManagerScreen(),
      ),
      GoRoute(
        path: RouteNames.settings,
        builder: (_, _) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'theme',
            builder: (_, _) => const ThemeSettingsScreen(),
          ),
          GoRoute(
            path: 'playback',
            builder: (_, _) => const PlaybackSettingsScreen(),
          ),
          GoRoute(
            path: 'storage',
            builder: (_, _) => const StorageSettingsScreen(),
          ),
          GoRoute(
            path: 'statistics',
            builder: (_, _) => const StatisticsScreen(),
          ),
          GoRoute(
            path: 'storage-manager',
            builder: (_, _) => const StorageManagerScreen(),
          ),
          GoRoute(
            path: 'about',
            builder: (_, _) => const AboutScreen(),
          ),
        ],
      ),

      // ─── Players ───
      GoRoute(
        path: RouteNames.videoPlayer,
        builder: (_, state) =>
            VideoPlayerScreen(mediaId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: RouteNames.audioPlayer,
        builder: (_, state) =>
            AudioPlayerScreen(mediaId: state.pathParameters['id']!),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
}