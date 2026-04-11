import 'package:cloudbase_flutter/cloudbase_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:spotify/data/repository/auth/auth_repository_impl.dart';
import 'package:spotify/data/source/auth/auth_cloudbase_service.dart';
import 'package:spotify/domain/repository/auth/auth.dart';
import 'package:spotify/domain/usecases/auth/send_phone_otp.dart';
import 'package:spotify/domain/usecases/auth/signin.dart';
import 'package:spotify/domain/usecases/auth/signup.dart';
import 'package:spotify/domain/usecases/auth/verify_phone_otp.dart';
import 'package:spotify/domain/usecases/auth/verify_signup_otp.dart';

final sl = GetIt.instance;

Future<void> initializeDependencies({required CloudBase cloudbaseApp}) async {
  sl.registerSingleton<CloudBase>(cloudbaseApp);

  sl.registerSingleton<AuthCloudbaseService>(AuthCloudbaseServiceImpl());

  sl.registerSingleton<AuthRepository>(AuthRepositoryImpl());

  sl.registerSingleton<SignupUseCase>(SignupUseCase());

  sl.registerSingleton<SigninUseCase>(SigninUseCase());

  sl.registerSingleton<VerifySignupOtpUseCase>(VerifySignupOtpUseCase());

  sl.registerSingleton<SendPhoneOtpUseCase>(SendPhoneOtpUseCase());

  sl.registerSingleton<VerifyPhoneOtpUseCase>(VerifyPhoneOtpUseCase());
}
