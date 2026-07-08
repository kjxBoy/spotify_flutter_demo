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

  /// 切换歌曲收藏状态（toggle）：
  /// - 若该歌曲尚未收藏 → 添加收藏，返回 Right(true)
  /// - 若该歌曲已收藏   → 取消收藏，返回 Right(false)
  /// - 操作失败         → 返回 Left(错误信息)
  ///
  /// 实际的增删逻辑在云函数 `addOrRemoveFavoriteSong` 中执行，
  /// Flutter 端只负责发起调用并解析结果。
  @override
  Future<Either<dynamic, dynamic>> addOrRemoveFavoriteSong(String songId) async {
    try {
      // 调用同名云函数，传入目标歌曲 ID
      final result = await _app.callFunction(
        name: 'addOrRemoveFavoriteSong',
        data: {'songId': songId},
      );

      // 第一层校验：HTTP 层面的错误（code 不为 null 且不是成功码）
      // CloudBase SDK 成功时 code 为 null 或 '0'，其余视为异常
      if (result.code != null && result.code != '0' && result.code != '200') {
        return Left(result.message ?? '操作失败');
      }

      // result.result 是云函数 return 的对象，例如：
      //   { code: 0, action: 'added', songId: 'xxx' }
      //   { code: 0, action: 'removed', songId: 'xxx' }
      //   { code: 401, message: '用户未登录' }
      final resultData = result.result;
      if (resultData is Map) {
        // 第二层校验：业务层面的错误（云函数内部返回非 0 code）
        final code = resultData['code'];
        if (code != null && code != 0 && code != '0') {
          return Left(resultData['message'] ?? '操作失败');
        }

        // 根据云函数返回的 action 判断本次操作是添加还是移除
        // action == 'added'   → true  （当前已收藏）
        // action == 'removed' → false （当前已取消收藏）
        final action = resultData['action'];
        return Right(action == 'added');
      }

      return const Left('返回数据格式异常');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<dynamic, dynamic>> getNewsSongs() async {
    try {
      final result = await _app.callFunction(
        name: 'getNewSongs',
        data: {'limit': 4, 'skip': 0},
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
  Future<Either<dynamic, dynamic>> getPlayList() async {
    try {
      final result = await _app.callFunction(
        name: 'getNewSongs',
        data: {'limit': 50, 'skip': 4},
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
  Future<Either<dynamic, dynamic>> getUserFavoriteSongs() async {
    try {
      final result = await _app.callFunction(
        name: 'getUserFavoriteSongs',
        data: {},
      );

      if (result.code != null && result.code != '0' && result.code != '200') {
        return Left(result.message ?? '获取收藏歌曲失败');
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
        model.isFavorite = true;
        return model.toEntity();
      }).toList();

      return Right(songs);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<bool> isFavoriteSong(String songId) async {
    try {
      final result = await _app.callFunction(
        name: 'isFavoriteSong',
        data: {'songId': songId},
      );

      if (result.code != null && result.code != '0' && result.code != '200') {
        return false;
      }

      final resultData = result.result;
      if (resultData is Map) {
        return (resultData['isFavorite'] as bool?) ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
}