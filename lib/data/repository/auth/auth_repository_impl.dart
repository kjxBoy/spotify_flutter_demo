import 'package:dartz/dartz.dart';
import 'package:spotify/domain/models/auth/signin_params.dart';
import 'package:spotify/domain/models/auth/signup_params.dart';
import 'package:spotify/data/source/auth/auth_firebase_service.dart';

import '../../../domain/repository/auth/auth.dart';
import '../../../service_locator.dart';

class AuthRepositoryImpl extends AuthRepository {
  @override
  Future<Either> signin(SigninParams signinParams) async {
    return await sl<AuthFirebaseService>().signin(signinParams);
  }

  @override
  Future<Either> signup(SignupParams signupParams) async {
    return await sl<AuthFirebaseService>().signup(signupParams);
  }

}