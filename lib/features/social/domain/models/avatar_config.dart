class AvatarConfig {
  final String emoji;
  final int colorIndex;

  const AvatarConfig({this.emoji = '😀', this.colorIndex = 0});

  static const _colors = [
    0xFF6C5CE7,
    0xFF00B894,
    0xFFE17055,
    0xFFFDCB6E,
    0xFF0984E3,
    0xFFE84393,
    0xFF00CEC9,
    0xFFD63031,
  ];

  int get color => _colors[colorIndex % _colors.length];

  AvatarConfig copyWith({String? emoji, int? colorIndex}) => AvatarConfig(
        emoji: emoji ?? this.emoji,
        colorIndex: colorIndex ?? this.colorIndex,
      );

  Map<String, dynamic> toJson() => {'emoji': emoji, 'colorIndex': colorIndex};

  factory AvatarConfig.fromJson(Map<String, dynamic> json) => AvatarConfig(
        emoji: json['emoji'] as String? ?? '😀',
        colorIndex: json['colorIndex'] as int? ?? 0,
      );
}
