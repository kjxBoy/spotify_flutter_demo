import 'package:dartz/dartz.dart';
import 'package:spotify/data/models/song/song.dart';
import 'package:cloudbase_flutter/cloudbase_flutter.dart' as tcb;

import '../../../service_locator.dart';

abstract class SongCloudbaseService {
  Future<Either> getNewsSongs();
  Future<Either> getPlayList();
  Future<Either> addOrRemoveFavoriteSong(String songId);
  Future<bool> isFavoriteSong(String songId);
  Future<Either> getUserFavoriteSongs();
}


class SongCloudbaseServiceImpl extends SongCloudbaseService {

  tcb.CloudBase get _app => sl<tcb.CloudBase>();

  @override
  Future<Either<dynamic, dynamic>> addOrRemoveFavoriteSong(String songId) {
    // TODO: implement addOrRemoveFavoriteSong
    throw UnimplementedError();
  }

  @override
  Future<Either<dynamic, dynamic>> getNewsSongs() async {
    try {
      final result = await _app.callFunction(
        name: 'getNewSongs',
        data: {'limit': 50, 'skip': 0},
      );
      if (result.message != null && result.code != null && result.code != '0') {
        return Left(result.message ?? '获取歌曲列表失败');
      }

      final resultData = result.result;
      final records = resultData is Map
          ? (resultData['data'] as List?) ?? []
          : resultData is List
              ? resultData
              : [];
      final songs = records.map((record) {
        final map = Map<String, dynamic>.from(record as Map);
        final model = SongModel.fromJson(map);
        model.songId = map['_id']?.toString();
        model.isFavorite = (map['isFavorite'] as bool?) ?? false;
        return model.toEntity();
      }).toList();

      return Right(songs);
    } catch (e) {
      return Left(e.toString());
    }
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