import 'package:dartz/dartz.dart';
import 'package:spotify/core/usecase/usecase.dart';
import 'package:spotify/domain/models/auth/verify_otp_params.dart';
import 'package:spotify/domain/repository/auth/auth.dart';
import 'package:spotify/service_locator.dart';

class VerifyPhoneOtpUseCase implements UseCase<Either, VerifyOtpParams> {
  @override
  Future<Either> call({VerifyOtpParams? params}) async {
    return sl<AuthRepository>().verifyPhoneOtp(params!);
  }
}
