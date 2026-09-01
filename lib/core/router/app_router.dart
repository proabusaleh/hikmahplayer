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
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../presentation/screens/home/me/me_tab.dart';
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
        return RouteNames.video;
      }
      return null;
    },
    routes: [
      // ─── Splash & onboarding ───
      GoRoute(
        path: RouteNames.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/scanning',
        builder: (_, __) => const ScanningScreen(),
      ),

      // ─── Home shell (3 tabs) ───
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            path: RouteNames.video,
            pageBuilder: (_, __) => const NoTransitionPage(child: VideoTab()),
          ),
          GoRoute(
            path: RouteNames.music,
            pageBuilder: (_, __) => const NoTransitionPage(child: MusicTab()),
          ),
          GoRoute(
            path: RouteNames.me,
            pageBuilder: (_, __) => const NoTransitionPage(child: MeTab()),
          ),
        ],
      ),
      GoRoute(
        path: RouteNames.home,
        redirect: (_, __) => RouteNames.video,
      ),

      // ─── Overlay screens ───
      GoRoute(
        path: RouteNames.search,
        builder: (_, __) => const SearchScreen(),
      ),
      GoRoute(
        path: RouteNames.favorites,
        builder: (_, __) => const FavoritesScreen(),
      ),
      GoRoute(
        path: RouteNames.history,
        builder: (_, __) => const HistoryScreen(),
      ),
      GoRoute(
        path: RouteNames.settings,
        builder: (_, __) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'theme',
            builder: (_, __) => const ThemeSettingsScreen(),
          ),
          GoRoute(
            path: 'playback',
            builder: (_, __) => const PlaybackSettingsScreen(),
          ),
          GoRoute(
            path: 'storage',
            builder: (_, __) => const StorageSettingsScreen(),
          ),
          GoRoute(
            path: 'about',
            builder: (_, __) => const AboutScreen(),
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