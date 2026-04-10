import 'package:dartz/dartz.dart';
import 'package:spotify/domain/models/auth/signup_params.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthFirebaseService {
  Future<Either> signup(SignupParams signupParams);

  Future<void> signin();
}

class AuthFirebaseServiceImpl extends AuthFirebaseService {
  @override
  Future<void> signin() {
    // TODO: implement signin
    throw UnimplementedError();
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
