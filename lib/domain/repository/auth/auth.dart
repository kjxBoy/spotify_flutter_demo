import 'package:dartz/dartz.dart';
import 'package:spotify/domain/models/auth/signin_params.dart';
import 'package:spotify/domain/models/auth/signup_params.dart';

abstract class AuthRepository {

  Future<Either> signup(SignupParams signupParams);

  Future<Either> signin(SigninParams signinParams);

}