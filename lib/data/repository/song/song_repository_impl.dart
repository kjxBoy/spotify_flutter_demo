
import 'package:dartz/dartz.dart';
import 'package:spotify/domain/repository/song/song.dart';

import '../../../service_locator.dart';
import '../../source/song/song_cloudbase_service.dart';

class SongRepositoryImpl extends SongRepository {
  @override
  Future<Either<dynamic, dynamic>> addOrRemoveFavoriteSongs(String songId) {
    return sl<SongCloudbaseService>().addOrRemoveFavoriteSong(songId);
  }

  @override
  Future<Either<dynamic, dynamic>> getNewsSongs() {
    return sl<SongCloudbaseService>().getNewsSongs();
  }

  @override
  Future<Either<dynamic, dynamic>> getPlayList() {
    return sl<SongCloudbaseService>().getPlayList();
  }

  @override
  Future<Either<dynamic, dynamic>> getUserFavoriteSongs() {
    return sl<SongCloudbaseService>().getUserFavoriteSongs();
  }

  @override
  Future<bool> isFavoriteSong(String songId) {
    return sl<SongCloudbaseService>().isFavoriteSong(songId);
  }

}