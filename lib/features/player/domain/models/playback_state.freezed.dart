// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'playback_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PlaybackState {

 PlaybackStatus get status; MediaItem? get currentMedia; Duration get position; Duration get duration; Duration get bufferedPosition; double get speed; double get volume; bool get isMuted; LoopMode get loopMode; bool get shuffleEnabled; List<MediaItem> get queue; int get currentIndex; VideoFit get videoFit; String? get errorMessage;
/// Create a copy of PlaybackState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaybackStateCopyWith<PlaybackState> get copyWith => _$PlaybackStateCopyWithImpl<PlaybackState>(this as PlaybackState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaybackState&&(identical(other.status, status) || other.status == status)&&(identical(other.currentMedia, currentMedia) || other.currentMedia == currentMedia)&&(identical(other.position, position) || other.position == position)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.bufferedPosition, bufferedPosition) || other.bufferedPosition == bufferedPosition)&&(identical(other.speed, speed) || other.speed == speed)&&(identical(other.volume, volume) || other.volume == volume)&&(identical(other.isMuted, isMuted) || other.isMuted == isMuted)&&(identical(other.loopMode, loopMode) || other.loopMode == loopMode)&&(identical(other.shuffleEnabled, shuffleEnabled) || other.shuffleEnabled == shuffleEnabled)&&const DeepCollectionEquality().equals(other.queue, queue)&&(identical(other.currentIndex, currentIndex) || other.currentIndex == currentIndex)&&(identical(other.videoFit, videoFit) || other.videoFit == videoFit)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,status,currentMedia,position,duration,bufferedPosition,speed,volume,isMuted,loopMode,shuffleEnabled,const DeepCollectionEquality().hash(queue),currentIndex,videoFit,errorMessage);

@override
String toString() {
  return 'PlaybackState(status: $status, currentMedia: $currentMedia, position: $position, duration: $duration, bufferedPosition: $bufferedPosition, speed: $speed, volume: $volume, isMuted: $isMuted, loopMode: $loopMode, shuffleEnabled: $shuffleEnabled, queue: $queue, currentIndex: $currentIndex, videoFit: $videoFit, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $PlaybackStateCopyWith<$Res>  {
  factory $PlaybackStateCopyWith(PlaybackState value, $Res Function(PlaybackState) _then) = _$PlaybackStateCopyWithImpl;
@useResult
$Res call({
 PlaybackStatus status, MediaItem? currentMedia, Duration position, Duration duration, Duration bufferedPosition, double speed, double volume, bool isMuted, LoopMode loopMode, bool shuffleEnabled, List<MediaItem> queue, int currentIndex, VideoFit videoFit, String? errorMessage
});




}
/// @nodoc
class _$PlaybackStateCopyWithImpl<$Res>
    implements $PlaybackStateCopyWith<$Res> {
  _$PlaybackStateCopyWithImpl(this._self, this._then);

  final PlaybackState _self;
  final $Res Function(PlaybackState) _then;

/// Create a copy of PlaybackState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? currentMedia = freezed,Object? position = null,Object? duration = null,Object? bufferedPosition = null,Object? speed = null,Object? volume = null,Object? isMuted = null,Object? loopMode = null,Object? shuffleEnabled = null,Object? queue = null,Object? currentIndex = null,Object? videoFit = null,Object? errorMessage = freezed,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PlaybackStatus,currentMedia: freezed == currentMedia ? _self.currentMedia : currentMedia // ignore: cast_nullable_to_non_nullable
as MediaItem?,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as Duration,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration,bufferedPosition: null == bufferedPosition ? _self.bufferedPosition : bufferedPosition // ignore: cast_nullable_to_non_nullable
as Duration,speed: null == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as double,volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double,isMuted: null == isMuted ? _self.isMuted : isMuted // ignore: cast_nullable_to_non_nullable
as bool,loopMode: null == loopMode ? _self.loopMode : loopMode // ignore: cast_nullable_to_non_nullable
as LoopMode,shuffleEnabled: null == shuffleEnabled ? _self.shuffleEnabled : shuffleEnabled // ignore: cast_nullable_to_non_nullable
as bool,queue: null == queue ? _self.queue : queue // ignore: cast_nullable_to_non_nullable
as List<MediaItem>,currentIndex: null == currentIndex ? _self.currentIndex : currentIndex // ignore: cast_nullable_to_non_nullable
as int,videoFit: null == videoFit ? _self.videoFit : videoFit // ignore: cast_nullable_to_non_nullable
as VideoFit,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc


class _PlaybackState extends PlaybackState {
  const _PlaybackState({this.status = PlaybackStatus.idle, this.currentMedia, this.position = Duration.zero, this.duration = Duration.zero, this.bufferedPosition = Duration.zero, this.speed = 1.0, this.volume = 1.0, this.isMuted = false, this.loopMode = LoopMode.none, this.shuffleEnabled = false, final  List<MediaItem> queue = const [], this.currentIndex = 0, this.videoFit = VideoFit.contain, this.errorMessage}): _queue = queue,super._();
  

@override@JsonKey() final  PlaybackStatus status;
@override final  MediaItem? currentMedia;
@override@JsonKey() final  Duration position;
@override@JsonKey() final  Duration duration;
@override@JsonKey() final  Duration bufferedPosition;
@override@JsonKey() final  double speed;
@override@JsonKey() final  double volume;
@override@JsonKey() final  bool isMuted;
@override@JsonKey() final  LoopMode loopMode;
@override@JsonKey() final  bool shuffleEnabled;
 final  List<MediaItem> _queue;
@override@JsonKey() List<MediaItem> get queue {
  if (_queue is EqualUnmodifiableListView) return _queue;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_queue);
}

@override@JsonKey() final  int currentIndex;
@override@JsonKey() final  VideoFit videoFit;
@override final  String? errorMessage;

/// Create a copy of PlaybackState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlaybackStateCopyWith<_PlaybackState> get copyWith => __$PlaybackStateCopyWithImpl<_PlaybackState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlaybackState&&(identical(other.status, status) || other.status == status)&&(identical(other.currentMedia, currentMedia) || other.currentMedia == currentMedia)&&(identical(other.position, position) || other.position == position)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.bufferedPosition, bufferedPosition) || other.bufferedPosition == bufferedPosition)&&(identical(other.speed, speed) || other.speed == speed)&&(identical(other.volume, volume) || other.volume == volume)&&(identical(other.isMuted, isMuted) || other.isMuted == isMuted)&&(identical(other.loopMode, loopMode) || other.loopMode == loopMode)&&(identical(other.shuffleEnabled, shuffleEnabled) || other.shuffleEnabled == shuffleEnabled)&&const DeepCollectionEquality().equals(other._queue, _queue)&&(identical(other.currentIndex, currentIndex) || other.currentIndex == currentIndex)&&(identical(other.videoFit, videoFit) || other.videoFit == videoFit)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,status,currentMedia,position,duration,bufferedPosition,speed,volume,isMuted,loopMode,shuffleEnabled,const DeepCollectionEquality().hash(_queue),currentIndex,videoFit,errorMessage);

@override
String toString() {
  return 'PlaybackState(status: $status, currentMedia: $currentMedia, position: $position, duration: $duration, bufferedPosition: $bufferedPosition, speed: $speed, volume: $volume, isMuted: $isMuted, loopMode: $loopMode, shuffleEnabled: $shuffleEnabled, queue: $queue, currentIndex: $currentIndex, videoFit: $videoFit, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$PlaybackStateCopyWith<$Res> implements $PlaybackStateCopyWith<$Res> {
  factory _$PlaybackStateCopyWith(_PlaybackState value, $Res Function(_PlaybackState) _then) = __$PlaybackStateCopyWithImpl;
@override @useResult
$Res call({
 PlaybackStatus status, MediaItem? currentMedia, Duration position, Duration duration, Duration bufferedPosition, double speed, double volume, bool isMuted, LoopMode loopMode, bool shuffleEnabled, List<MediaItem> queue, int currentIndex, VideoFit videoFit, String? errorMessage
});




}
/// @nodoc
class __$PlaybackStateCopyWithImpl<$Res>
    implements _$PlaybackStateCopyWith<$Res> {
  __$PlaybackStateCopyWithImpl(this._self, this._then);

  final _PlaybackState _self;
  final $Res Function(_PlaybackState) _then;

/// Create a copy of PlaybackState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? currentMedia = freezed,Object? position = null,Object? duration = null,Object? bufferedPosition = null,Object? speed = null,Object? volume = null,Object? isMuted = null,Object? loopMode = null,Object? shuffleEnabled = null,Object? queue = null,Object? currentIndex = null,Object? videoFit = null,Object? errorMessage = freezed,}) {
  return _then(_PlaybackState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PlaybackStatus,currentMedia: freezed == currentMedia ? _self.currentMedia : currentMedia // ignore: cast_nullable_to_non_nullable
as MediaItem?,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as Duration,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration,bufferedPosition: null == bufferedPosition ? _self.bufferedPosition : bufferedPosition // ignore: cast_nullable_to_non_nullable
as Duration,speed: null == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as double,volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double,isMuted: null == isMuted ? _self.isMuted : isMuted // ignore: cast_nullable_to_non_nullable
as bool,loopMode: null == loopMode ? _self.loopMode : loopMode // ignore: cast_nullable_to_non_nullable
as LoopMode,shuffleEnabled: null == shuffleEnabled ? _self.shuffleEnabled : shuffleEnabled // ignore: cast_nullable_to_non_nullable
as bool,queue: null == queue ? _self._queue : queue // ignore: cast_nullable_to_non_nullable
as List<MediaItem>,currentIndex: null == currentIndex ? _self.currentIndex : currentIndex // ignore: cast_nullable_to_non_nullable
as int,videoFit: null == videoFit ? _self.videoFit : videoFit // ignore: cast_nullable_to_non_nullable
as VideoFit,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
