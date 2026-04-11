import 'package:dartz/dartz.dart';
import 'package:spotify/domain/models/auth/phone_auth_params.dart';
import 'package:spotify/domain/models/auth/signin_params.dart';
import 'package:spotify/domain/models/auth/signup_params.dart';
import 'package:spotify/domain/models/auth/verify_otp_params.dart';

abstract class AuthRepository {
  Future<Either> signup(SignupParams signupParams);

  Future<Either> verifySignupOtp(VerifyOtpParams params);

  Future<Either> signin(SigninParams signinParams);

  Future<Either> sendPhoneOtp(PhoneAuthParams params);

  Future<Either> verifyPhoneOtp(VerifyOtpParams params);
}
