import 'package:dartz/dartz.dart';
import 'package:spotify/core/usecase/usecase.dart';
import 'package:spotify/domain/models/auth/signin_params.dart';
import 'package:spotify/domain/repository/auth/auth.dart';

import '../../../service_locator.dart';
import '../../repository/song/song.dart';

class GetNewsSongsUseCase implements UseCase<Either, SigninParams> {

  @override
  Future<Either> call({params}) async {
    return await sl<SongRepository>().getNewsSongs();
  }

}