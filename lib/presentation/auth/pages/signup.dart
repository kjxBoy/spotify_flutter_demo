import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:spotify/common/widgets/appbar/app_bar.dart';
import 'package:spotify/common/widgets/button/basic_app_button.dart';
import 'package:spotify/core/configs/assets/app_vectors.dart';

class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: _signText(context),
      appBar: BasicAppbar(
        title: SvgPicture.asset(AppVectors.logo, height: 40, width: 40),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _registerText(),
            const SizedBox(height: 50),
            _fullNameField(context),
            const SizedBox(height: 20),
            _emailField(context),
            const SizedBox(height: 20),
            _password(context),
            const SizedBox(height: 20),
            BasicAppButton(onPressed: () {}, title: 'Sign In'),
          ],
        ),
      ),
    );
  }
}

Widget _registerText() {
  return Center(
    child: const Text(
      'Register',
      style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
    ),
  );
}

Widget _fullNameField(BuildContext context) {
  return TextField(
    decoration: const InputDecoration(
      hintText: 'Full Name',
    ).applyDefaults(Theme.of(context).inputDecorationTheme),
  );
}

Widget _emailField(BuildContext context) {
  return TextField(
    decoration: const InputDecoration(
      hintText: 'Enter Email',
    ).applyDefaults(Theme.of(context).inputDecorationTheme),
  );
}

Widget _password(BuildContext context) {
  return TextField(
    decoration: const InputDecoration(
      hintText: 'Password',
    ).applyDefaults(Theme.of(context).inputDecorationTheme),
  );
}

Widget _signText(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 30),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Do you have an account? ',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        TextButton(onPressed: () {}, child: const Text('Sign In')),
      ],
    ),
  );
}
