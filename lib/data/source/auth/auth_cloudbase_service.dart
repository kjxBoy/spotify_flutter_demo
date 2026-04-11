import 'package:cloudbase_flutter/cloudbase_flutter.dart' as tcb;
import 'package:dartz/dartz.dart';
import 'package:spotify/domain/models/auth/phone_auth_params.dart';
import 'package:spotify/domain/models/auth/signin_params.dart';
import 'package:spotify/domain/models/auth/signup_params.dart';
import 'package:spotify/domain/models/auth/verify_otp_params.dart';
import 'package:spotify/service_locator.dart';

abstract class AuthCloudbaseService {
  Future<Either> signup(SignupParams params);

  Future<Either> verifySignupOtp(VerifyOtpParams params);

  Future<Either> signin(SigninParams params);

  Future<Either> sendPhoneOtp(PhoneAuthParams params);

  Future<Either> verifyPhoneOtp(VerifyOtpParams params);
}

class AuthCloudbaseServiceImpl extends AuthCloudbaseService {
  tcb.CloudBase get _app => sl<tcb.CloudBase>();

  // Stored OTP verification callbacks for the two-step auth flows
  Future<tcb.CloudBaseResponse<tcb.SignInResData>> Function(tcb.VerifyOtpParams)? _pendingSignupVerify;
  Future<tcb.CloudBaseResponse<tcb.SignInResData>> Function(tcb.VerifyOtpParams)? _pendingPhoneVerify;

  @override
  Future<Either> signup(SignupParams params) async {
    final result = await _app.auth.signUp(
      tcb.SignUpReq(
        email: params.email,
        password: params.password,
        nickname: params.fullName,
      ),
    );
    if (!result.isSuccess) {
      return Left(_mapAuthError(result.error));
    }
    _pendingSignupVerify = result.data?.verifyOtp;
    return const Right('Verification email sent');
  }

  @override
  Future<Either> verifySignupOtp(VerifyOtpParams params) async {
    if (_pendingSignupVerify == null) {
      return const Left('No pending email verification. Please register again.');
    }
    final result = await _pendingSignupVerify!(
      tcb.VerifyOtpParams(token: params.token),
    );
    if (!result.isSuccess) {
      return Left(_mapAuthError(result.error));
    }
    _pendingSignupVerify = null;
    return const Right('Signup was Successful');
  }

  @override
  Future<Either> signin(SigninParams params) async {
    final result = await _app.auth.signInWithPassword(
      tcb.SignInWithPasswordReq(
        email: params.email,
        password: params.password,
      ),
    );
    if (!result.isSuccess) {
      return Left(_mapAuthError(result.error));
    }
    return const Right('Login was Successful');
  }

  @override
  Future<Either> sendPhoneOtp(PhoneAuthParams params) async {
    final result = await _app.auth.signInWithOtp(
      tcb.SignInWithOtpReq(phone: params.phone),
    );
    if (!result.isSuccess) {
      return Left(_mapAuthError(result.error));
    }
    _pendingPhoneVerify = result.data?.verifyOtp;
    return const Right('OTP sent');
  }

  @override
  Future<Either> verifyPhoneOtp(VerifyOtpParams params) async {
    if (_pendingPhoneVerify == null) {
      return const Left('No pending phone verification. Please try again.');
    }
    final result = await _pendingPhoneVerify!(
      tcb.VerifyOtpParams(token: params.token),
    );
    if (!result.isSuccess) {
      return Left(_mapAuthError(result.error));
    }
    _pendingPhoneVerify = null;
    return const Right('Login was Successful');
  }

  String _mapAuthError(tcb.AuthError? error) {
    if (error == null) return 'An unknown error occurred.';
    switch (error.code) {
      case 'OPERATION_FAIL':
        return 'An account already exists with that email.';
      case 'AUTH_INVALID_PASSWORD':
        return 'Wrong password provided for that user.';
      case 'AUTH_USER_NOT_FOUND':
        return 'No user found for that email.';
      case 'invalid_params':
        return error.message ?? 'Invalid parameters.';
      default:
        return error.message ?? 'Operation failed. Please try again.';
    }
  }
}
