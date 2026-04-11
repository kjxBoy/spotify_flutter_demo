import 'package:dartz/dartz.dart';
import 'package:spotify/domain/models/auth/phone_auth_params.dart';
import 'package:spotify/domain/models/auth/signin_params.dart';
import 'package:spotify/domain/models/auth/signup_params.dart';
import 'package:spotify/domain/models/auth/verify_otp_params.dart';
import 'package:spotify/data/source/auth/auth_cloudbase_service.dart';
import 'package:spotify/domain/repository/auth/auth.dart';
import 'package:spotify/service_locator.dart';

class AuthRepositoryImpl extends AuthRepository {
  @override
  Future<Either> signup(SignupParams signupParams) async {
    return sl<AuthCloudbaseService>().signup(signupParams);
  }

  @override
  Future<Either> verifySignupOtp(VerifyOtpParams params) async {
    return sl<AuthCloudbaseService>().verifySignupOtp(params);
  }

  @override
  Future<Either> signin(SigninParams signinParams) async {
    return sl<AuthCloudbaseService>().signin(signinParams);
  }

  @override
  Future<Either> sendPhoneOtp(PhoneAuthParams params) async {
    return sl<AuthCloudbaseService>().sendPhoneOtp(params);
  }

  @override
  Future<Either> verifyPhoneOtp(VerifyOtpParams params) async {
    return sl<AuthCloudbaseService>().verifyPhoneOtp(params);
  }
}
