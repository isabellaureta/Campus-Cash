import 'package:campuscash/auth/auth_user.dart';
import 'package:campuscash/auth/firebase_auth_provider.dart' as firebase;
import 'package:campuscash/auth/auth_provider.dart' as auth_provider;

class AuthService implements auth_provider.AuthProvider {
  final auth_provider.AuthProvider provider;
  const AuthService(this.provider);

  factory AuthService.firebase() => AuthService(firebase.FirebaseAuthProvider());

  @override
  Future<AuthUser> createUser({
    required String email,
    required String password,
  }) =>
      provider.createUser(
        email: email,
        password: password,
      );

  @override
  AuthUser? get currentUser => provider.currentUser;

  @override
  Future<AuthUser> logIn({
    required String email,
    required String password,
  }) =>
      provider.logIn(
        email: email,
        password: password,
      );

  @override
  Future<void> logOut() => provider.logOut();

  @override
  Future<void> sendEmailVerification() => provider.sendEmailVerification();

  @override
  Future<void> initialize() => provider.initialize();

  @override
  Future<void> sendPasswordReset({required String email}) =>
      provider.sendPasswordReset(email: email);
}
