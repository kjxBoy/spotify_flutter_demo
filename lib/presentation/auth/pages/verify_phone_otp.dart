import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:spotify/common/widgets/appbar/app_bar.dart';
import 'package:spotify/common/widgets/button/basic_app_button.dart';
import 'package:spotify/core/configs/assets/app_vectors.dart';
import 'package:spotify/domain/models/auth/verify_otp_params.dart';
import 'package:spotify/domain/usecases/auth/verify_phone_otp.dart';
import 'package:spotify/presentation/root/pages/root.dart';
import 'package:spotify/service_locator.dart';

class VerifyPhoneOtpPage extends StatelessWidget {
  final String phone;

  VerifyPhoneOtpPage({super.key, required this.phone});

  final TextEditingController _otpController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BasicAppbar(
        title: SvgPicture.asset(AppVectors.logo, height: 40, width: 40),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Verify Phone',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Enter the verification code sent to\n$phone',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 50),
            _otpField(context),
            const SizedBox(height: 30),
            BasicAppButton(
              onPressed: () async {
                final result = await sl<VerifyPhoneOtpUseCase>().call(
                  params: VerifyOtpParams(token: _otpController.text.trim()),
                );

                result.fold(
                  (l) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  (r) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const RootPage()),
                      (route) => false,
                    );
                  },
                );
              },
              title: 'Verify',
            ),
          ],
        ),
      ),
    );
  }

  Widget _otpField(BuildContext context) {
    return TextField(
      controller: _otpController,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      maxLength: 6,
      style: const TextStyle(fontSize: 24, letterSpacing: 8),
      decoration: const InputDecoration(
        hintText: '------',
        counterText: '',
      ).applyDefaults(Theme.of(context).inputDecorationTheme),
    );
  }
}
