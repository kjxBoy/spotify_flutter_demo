
import 'package:dartz/dartz.dart';
import 'package:spotify/domain/repository/song/song.dart';

import '../../../service_locator.dart';
import '../../source/song/song_cloudbase_service.dart';

class SongRepositoryImpl extends SongRepository {
  @override
  Future<Either<dynamic, dynamic>> addOrRemoveFavoriteSongs(String songId) {
    // TODO: implement addOrRemoveFavoriteSongs
    throw UnimplementedError();
  }

  @override
  Future<Either<dynamic, dynamic>> getNewsSongs() {
    return sl<SongCloudbaseService>().getNewsSongs();
  }

  @override
  Future<Either<dynamic, dynamic>> getPlayList() {
    // TODO: implement getPlayList
    throw UnimplementedError();
  }

  @override
  Future<Either<dynamic, dynamic>> getUserFavoriteSongs() {
    // TODO: implement getUserFavoriteSongs
    throw UnimplementedError();
  }

  @override
  Future<bool> isFavoriteSong(String songId) {
    // TODO: implement isFavoriteSong
    throw UnimplementedError();
  }

}