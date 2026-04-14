import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:spotify/common/widgets/appbar/app_bar.dart';
import 'package:spotify/common/widgets/button/basic_app_button.dart';
import 'package:spotify/core/configs/assets/app_vectors.dart';
import 'package:spotify/domain/models/auth/phone_auth_params.dart';
import 'package:spotify/domain/usecases/auth/send_phone_otp.dart';
import 'package:spotify/presentation/auth/pages/verify_phone_otp.dart';
import 'package:spotify/service_locator.dart';

class PhoneSigninPage extends StatelessWidget {
  PhoneSigninPage({super.key});

  final TextEditingController _phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // 👈 加这行
      child: Scaffold(
        appBar: BasicAppbar(
          title: SvgPicture.asset(AppVectors.logo, height: 40, width: 40),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Phone Sign Up / Sign In',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Enter your phone number to receive a\nverification code. New numbers will\nautomatically create an account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 50),
                _phoneField(context),
                const SizedBox(height: 30),
                BasicAppButton(
                  onPressed: () async {
                    final phone = _phoneController.text.trim();
                    if (phone.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter your phone number'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    final result = await sl<SendPhoneOtpUseCase>().call(
                      params: PhoneAuthParams(phone: phone),
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VerifyPhoneOtpPage(phone: phone),
                          ),
                        );
                      },
                    );
                  },
                  title: 'Send Code',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _phoneField(BuildContext context) {
    return TextField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      decoration: const InputDecoration(
        hintText: 'Phone Number (e.g. 13800138000)',
        prefixIcon: Icon(Icons.phone),
      ).applyDefaults(Theme.of(context).inputDecorationTheme),
    );
  }
}
