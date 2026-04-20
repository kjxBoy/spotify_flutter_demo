import 'dart:async';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:spotify/presentation/song_player/bloc/song_player_state.dart';

class SongPlayerCubit extends Cubit<SongPlayerState> {
  AudioPlayer audioPlayer = AudioPlayer();
  Duration songDuration = Duration.zero;
  Duration songPosition = Duration.zero;

  Timer? _positionTimer;
  DateTime? _playStartTime;
  Duration _positionAtPlayStart = Duration.zero;

  SongPlayerCubit() : super(SongPlayerLoading()) {
    audioPlayer.playerStateStream.listen((state) {
      if (state.playing) {
        _startPositionTimer();
      } else {
        _stopPositionTimer();
      }
    });
  }

  void _startPositionTimer() {
    _positionTimer?.cancel();
    _playStartTime = DateTime.now();
    _positionAtPlayStart = songPosition;
    _positionTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (audioPlayer.playing && _playStartTime != null) {
        final elapsed = DateTime.now().difference(_playStartTime!);
        songPosition = _positionAtPlayStart + elapsed;
        if (songDuration > Duration.zero && songPosition >= songDuration) {
          songPosition = songDuration;
          _stopPositionTimer();
        }
        updateSongPlayer();
      }
    });
  }

  void _stopPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = null;
  }

  void updateSongPlayer() {
    emit(SongPlayerLoaded());
  }

  /// [fallbackDuration] 来自数据库字段，当 AVPlayer 无法解析时长时使用
  Future<void> loadSong(String url, {Duration fallbackDuration = Duration.zero}) async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      await session.setActive(true);

      await audioPlayer.setUrl(url);
      final resolved = audioPlayer.duration;
      songDuration = (resolved != null && resolved > Duration.zero)
          ? resolved
          : fallbackDuration;
      emit(SongPlayerLoaded());
    } catch (e, stackTrace) {
      debugPrint('loadSong error: $e\n$stackTrace');
      emit(SongPlayerFailure());
    }
  }

  void playOrPauseSong() {
    if (audioPlayer.playing) {
      _positionAtPlayStart = songPosition;
      _stopPositionTimer();
      audioPlayer.pause();
    } else {
      audioPlayer.play();
    }
    emit(SongPlayerLoaded());
  }

  void seekTo(Duration position) {
    songPosition = position;
    _positionAtPlayStart = position;
    if (audioPlayer.playing) {
      _playStartTime = DateTime.now();
    }
    audioPlayer.seek(position);
    updateSongPlayer();
  }

  @override
  Future<void> close() {
    _stopPositionTimer();
    audioPlayer.dispose();
    return super.close();
  }
}
