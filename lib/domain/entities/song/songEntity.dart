import 'dart:ffi';

class SongEntity {
  final String title;
  final String artist;
  final num duration;
  final bool isFavorite;
  final String songId;
  final Float releaseDate;

  SongEntity({
    required this.title,
    required this.artist,
    required this.duration,
    required this.isFavorite,
    required this.songId,
    required this.releaseDate
  });
}