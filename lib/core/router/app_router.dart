import 'package:go_router/go_router.dart';

import '../../features/folders/presentation/screens/folder_path_screen.dart';
import '../../features/folders/presentation/screens/folders_screen.dart';
import '../../features/music/presentation/screens/album_screen.dart';
import '../../features/music/presentation/screens/artist_screen.dart';
import '../../features/music/presentation/screens/music_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/player/presentation/screens/audio_player_screen.dart';
import '../../features/player/presentation/screens/video_player_screen.dart';
import '../../features/playlists/presentation/screens/playlist_create_screen.dart';
import '../../features/playlists/presentation/screens/playlist_detail_screen.dart';
import '../../features/playlists/presentation/screens/playlist_edit_screen.dart';
import '../../features/playlists/presentation/screens/playlists_screen.dart';
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
import '../../features/videos/presentation/screens/video_details_screen.dart';
import '../../features/videos/presentation/screens/videos_screen.dart';
import '../../shared/shell/home_shell.dart';
import '../storage/prefs_service.dart';

GoRouter createAppRouter({required PrefsService prefs}) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final onboarded = prefs.onboardingCompleted;
      final location = state.matchedLocation;
      const guarded = ['/splash', '/onboarding', '/scanning'];
      if (!onboarded && !guarded.contains(location)) {
        return '/splash';
      }
      if (onboarded && location == '/onboarding') {
        return '/home/videos';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/scanning',
        builder: (context, state) => const ScanningScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(shell: shell),
        branches: [
          _videosBranch(),
          _musicBranch(),
          _foldersBranch(),
          _playlistsBranch(),
          _settingsBranch(),
        ],
      ),
      GoRoute(
        path: '/video-player/:id',
        builder: (context, state) =>
            VideoPlayerScreen(mediaId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/audio-player/:id',
        builder: (context, state) =>
            AudioPlayerScreen(mediaId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/favorites',
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const HistoryScreen(),
      ),
    ],
  );
}

StatefulShellBranch _videosBranch() => StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/home/videos',
          builder: (context, state) => const VideosScreen(),
          routes: [
            GoRoute(
              path: 'details/:id',
              builder: (context, state) => VideoDetailsScreen(
                mediaId: state.pathParameters['id']!,
              ),
            ),
          ],
        ),
      ],
    );

StatefulShellBranch _musicBranch() => StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/home/music',
          builder: (context, state) => const MusicScreen(),
          routes: [
            GoRoute(
              path: 'player/:id',
              builder: (context, state) => AudioPlayerScreen(
                mediaId: state.pathParameters['id']!,
              ),
            ),
            GoRoute(
              path: 'album/:id',
              builder: (context, state) =>
                  AlbumScreen(albumId: state.pathParameters['id']!),
            ),
            GoRoute(
              path: 'artist/:id',
              builder: (context, state) =>
                  ArtistScreen(artistId: state.pathParameters['id']!),
            ),
          ],
        ),
      ],
    );

StatefulShellBranch _foldersBranch() => StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/home/folders',
          builder: (context, state) => const FoldersScreen(),
          routes: [
            GoRoute(
              path: ':path',
              builder: (context, state) =>
                  FolderPathScreen(folderPath: state.pathParameters['path']!),
            ),
          ],
        ),
      ],
    );

StatefulShellBranch _playlistsBranch() => StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/home/playlists',
          builder: (context, state) => const PlaylistsScreen(),
          routes: [
            GoRoute(
              path: 'create',
              builder: (context, state) => const PlaylistCreateScreen(),
            ),
            GoRoute(
              path: ':id',
              builder: (context, state) => PlaylistDetailScreen(
                playlistId: state.pathParameters['id']!,
              ),
              routes: [
                GoRoute(
                  path: 'edit',
                  builder: (context, state) => PlaylistEditScreen(
                    playlistId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );

StatefulShellBranch _settingsBranch() => StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/home/settings',
          builder: (context, state) => const SettingsScreen(),
          routes: [
            GoRoute(
              path: 'theme',
              builder: (context, state) => const ThemeSettingsScreen(),
            ),
            GoRoute(
              path: 'playback',
              builder: (context, state) => const PlaybackSettingsScreen(),
            ),
            GoRoute(
              path: 'about',
              builder: (context, state) => const AboutScreen(),
            ),
            GoRoute(
              path: 'storage',
              builder: (context, state) => const StorageSettingsScreen(),
            ),
          ],
        ),
      ],
    );
