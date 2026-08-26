import 'package:flutter/material.dart';

import '../../../../core/di/app_scope.dart';

class PlaybackSettingsScreen extends StatefulWidget {
  const PlaybackSettingsScreen({super.key});

  @override
  State<PlaybackSettingsScreen> createState() => _PlaybackSettingsScreenState();
}

class _PlaybackSettingsScreenState extends State<PlaybackSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final prefs = AppScope.of(context).prefs;
    return Scaffold(
      appBar: AppBar(title: const Text('Playback')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Resume playback'),
            subtitle: const Text('Continue where you left off'),
            value: prefs.resumePlayback,
            onChanged: (v) => setState(() => prefs.resumePlayback = v),
          ),
          SwitchListTile(
            title: const Text('Auto-play next'),
            subtitle: const Text('Advance the queue automatically'),
            value: prefs.autoPlay,
            onChanged: (v) => setState(() => prefs.autoPlay = v),
          ),
          ListTile(
            title: const Text('Default speed'),
            trailing: DropdownButton<double>(
              value: prefs.defaultPlaybackSpeed,
              items: const [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text('${s}x'),
                      ))
                  .toList(),
              onChanged: (v) => setState(() {
                if (v != null) prefs.defaultPlaybackSpeed = v;
              }),
            ),
          ),
          ListTile(
            title: const Text('Default video fit'),
            trailing: DropdownButton<String>(
              value: prefs.defaultVideoFit,
              items: const [
                DropdownMenuItem(value: 'contain', child: Text('Contain')),
                DropdownMenuItem(value: 'cover', child: Text('Cover')),
                DropdownMenuItem(value: 'fill', child: Text('Fill')),
              ],
              onChanged: (v) => setState(() {
                if (v != null) prefs.defaultVideoFit = v;
              }),
            ),
          ),
          ListTile(
            title: const Text('Loop mode'),
            trailing: DropdownButton<String>(
              value: prefs.loopMode,
              items: const [
                DropdownMenuItem(value: 'none', child: Text('None')),
                DropdownMenuItem(value: 'one', child: Text('Repeat one')),
                DropdownMenuItem(value: 'all', child: Text('Repeat all')),
              ],
              onChanged: (v) => setState(() {
                if (v != null) prefs.loopMode = v;
              }),
            ),
          ),
        ],
      ),
    );
  }
}
