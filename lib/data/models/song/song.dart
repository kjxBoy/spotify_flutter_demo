import '../../../domain/entities/song/SongEntity.dart';

class SongModel {
  String? songId;
  String? artist;
  String? title;

  num? duration;
  double? releaseDate;
  bool? isFavorite;


  SongModel({
    required this.title,
    required this.artist,
    required this.duration,
    required this.releaseDate,
    required this.isFavorite,
    required this.songId,
  });

  SongModel.fromJson(Map<String, dynamic> data) {
    title = data['title'];
    artist = data['artist'];
    duration = data['duration'];
    releaseDate = (data['releaseDate'] as num?)?.toDouble();
  }
}

extension SongModelX on SongModel {

  SongEntity toEntity() {
    return SongEntity(
        title: title!,
        artist: artist!,
        duration: duration!,
        releaseDate: releaseDate!,
        isFavorite: isFavorite!,
        songId: songId!
    );
  }
}