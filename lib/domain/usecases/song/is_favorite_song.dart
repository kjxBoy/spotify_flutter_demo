import 'dart:ffi';

import 'package:dartz/dartz.dart';
import 'package:spotify/core/usecase/usecase.dart';
import 'package:spotify/domain/models/auth/signin_params.dart';
import 'package:spotify/domain/repository/auth/auth.dart';

import '../../../service_locator.dart';
import '../../repository/song/song.dart';

class IsFavoriteSongUseCase implements UseCase<bool, String> {

  @override
  Future<bool> call({String ? params}) async {
    return await sl<SongRepository>().isFavoriteSong(params!);
  }

}