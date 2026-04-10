import 'package:dartz/dartz.dart';
import 'package:spotify/domain/models/auth/signup_params.dart';

abstract class AuthRepository {

  Future<Either> signup(SignupParams signupParams);

  Future<void> signin();

}