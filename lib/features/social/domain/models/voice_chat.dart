enum VoiceState { idle, connecting, active, muted }

class VoiceChatState {
  final String memberId;
  final String memberName;
  final VoiceState state;
  final double volume;

  const VoiceChatState({
    required this.memberId,
    required this.memberName,
    required this.state,
    this.volume = 0,
  });

  VoiceChatState copyWith({VoiceState? state, double? volume}) => VoiceChatState(
        memberId: memberId,
        memberName: memberName,
        state: state ?? this.state,
        volume: volume ?? this.volume,
      );

  Map<String, dynamic> toJson() => {
        'memberId': memberId,
        'memberName': memberName,
        'state': state.name,
        'volume': volume,
      };

  factory VoiceChatState.fromJson(Map<String, dynamic> json) => VoiceChatState(
        memberId: json['memberId'] as String,
        memberName: json['memberName'] as String,
        state: VoiceState.values.asNameMap()[json['state']] ?? VoiceState.idle,
        volume: (json['volume'] as num?)?.toDouble() ?? 0,
      );
}
