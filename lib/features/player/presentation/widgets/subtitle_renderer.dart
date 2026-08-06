import 'package:flutter/material.dart';

import '../../../../core/di/app_scope.dart';
import '../../../../features/accessibility/domain/models/subtitle_style.dart';

/// Renders the engine's current subtitle cues with the accessibility layer's
/// customisable [SubtitleStyle].
///
/// The media_kit engine already decodes and selects the active subtitle track;
/// this widget is responsible only for styling the decoded text.
class SubtitleRenderer extends StatelessWidget {
  const SubtitleRenderer({
    super.key,
    required this.lines,
    this.alwaysVisible = false,
  });

  /// Decoded subtitle lines for the current position.
  final List<String> lines;

  /// When true the renderer stays visible even without active cues.
  final bool alwaysVisible;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final style = services.accessibility.settings.value.subtitleStyle;

    if (lines.isEmpty && !alwaysVisible) return const SizedBox.shrink();
    if (lines.isEmpty) return const SizedBox.shrink();

    final size = style.effectiveFontSize;
    final bg = style.effectiveBackgroundColor;

    final textStyle = TextStyle(
      fontSize: size,
      height: 1.25,
      color: Color(style.color),
      fontWeight: style.bold ? FontWeight.w600 : FontWeight.w400,
      fontStyle: style.italic ? FontStyle.italic : FontStyle.normal,
      fontFamily: style.fontFamily,
      letterSpacing: style.letterSpacing,
      shadows: style.shadow
          ? const [
              Shadow(blurRadius: 4, color: Colors.black, offset: Offset(0, 2)),
            ]
          : const [],
    );

    final container = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: bg == null
          ? null
          : BoxDecoration(
              color: Color(bg),
              borderRadius: BorderRadius.circular(6),
            ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Text(line, textAlign: _align(style.align), style: textStyle),
            ),
        ],
      ),
    );

    return Align(
      alignment: Alignment(0, 1 - style.verticalPosition * 2 - 0.3),
      child: container,
    );
  }

  TextAlign _align(SubtitleAlign align) {
    switch (align) {
      case SubtitleAlign.left:
        return TextAlign.left;
      case SubtitleAlign.center:
        return TextAlign.center;
      case SubtitleAlign.right:
        return TextAlign.right;
    }
  }
}
