import 'package:dartz/dartz.dart';
import 'package:spotify/core/usecase/usecase.dart';
import 'package:spotify/domain/models/auth/phone_auth_params.dart';
import 'package:spotify/domain/repository/auth/auth.dart';
import 'package:spotify/service_locator.dart';

class SendPhoneOtpUseCase implements UseCase<Either, PhoneAuthParams> {
  @override
  Future<Either> call({PhoneAuthParams? params}) async {
    return sl<AuthRepository>().sendPhoneOtp(params!);
  }
}
