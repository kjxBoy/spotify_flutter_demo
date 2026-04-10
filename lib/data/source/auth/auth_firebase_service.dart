import 'package:dartz/dartz.dart';
import 'package:spotify/domain/models/auth/signup_params.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../domain/models/auth/signin_params.dart';

abstract class AuthFirebaseService {
  Future<Either> signup(SignupParams signupParams);

  Future<Either> signin(SigninParams signinParams);
}

class AuthFirebaseServiceImpl extends AuthFirebaseService {
  @override
  Future<Either> signin(SigninParams signinParams) async {
    try {

      print('email : ${signinParams.email}, password: ${signinParams.password}');

      await FirebaseAuth.instance.signInWithEmailAndPassword(email: signinParams.email, password: signinParams.password);
      return const Right('login was Successful');
    } on FirebaseAuthException catch (e) {
      String message = '';

      if(e.code == 'invalid-email') {
        message = 'Not user found for that email';
      } else if (e.code == 'invalid-credential') {
        message = 'Wrong password provided for that user';
      }

      return Left(message);
    }
  }

  @override
  Future<Either> signup(SignupParams signupParams) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: signupParams.email,
        password: signupParams.password,
      );
      
      return const Right('Signup was Successful');
    } on FirebaseAuthException catch (e) {
      String message = '';
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak';
      } else if (e.code == 'email-already-in-use') {
        message = 'An account already exists with that email.';
      }
      return Left(message);
    }
  }
}
