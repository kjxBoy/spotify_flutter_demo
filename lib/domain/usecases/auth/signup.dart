import 'package:dartz/dartz.dart';
import 'package:spotify/core/usecase/usecase.dart';
import 'package:spotify/domain/models/auth/signup_params.dart';
import 'package:spotify/domain/repository/auth/auth.dart';

import '../../../service_locator.dart';

class SignupUseCase implements UseCase<Either, SignupParams> {

  @override
  Future<Either> call({SignupParams? params}) async {
    return sl<AuthRepository>().signup(params!);
  }

}
