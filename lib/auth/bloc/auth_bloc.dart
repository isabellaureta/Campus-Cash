import 'package:bloc/bloc.dart';
import 'package:campuscash/auth/auth_provider.dart';
import 'package:campuscash/auth/bloc/auth_event.dart';
import 'package:campuscash/auth/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(AuthProvider provider)
      : super(const AuthStateUninitialized(isLoading: true)) {

    on<AuthEventInitialize>(
      (event, emit) async {
        await provider.initialize();
        final user = provider.currentUser;

        // user is null so the state is 'logged out'
        if (user == null) {
          emit(
            const AuthStateLoggedOut(
              exception: null,
              isLoading: false,
            ),
          );

          // if user's email is not verified emits 'need verification' state
        } else if (!user.isEmailVerified) {
          emit(
            const AuthStateNeedsVerification(isLoading: false),
          );
          // user is not null and email is verified so 'logged in' state
        } else {
          emit(
            AuthStateLoggedIn(
              user: user,
              isLoading: false,
            ),
          );
        }
      },
    );

    // forgot password
    on<AuthEventForgotPassword>(
      (event, emit) async {
        emit(
          const AuthStateForgotPassword(
            exception: null,
            hasSentEmail: false,
            isLoading: false,
          ),
        );
        final email = event.email;

        // case when user just wants to go to forgot-password screen
        if (email == null) {
          return;
        }

        // user wants to send a forgot-password email
        emit(
          const AuthStateForgotPassword(
            exception: null,
            hasSentEmail: false,
            isLoading: true,
          ),
        );

        bool didSendEmail;
        Exception? exception;

        try {
          await provider.sendPasswordReset(email: email);
          didSendEmail = true;
          exception = null;
        } on Exception catch (e) {
          didSendEmail = false;
          exception = e;
        }

        emit(
          AuthStateForgotPassword(
            exception: exception,
            hasSentEmail: didSendEmail,
            isLoading: false,
          ),
        );
      },
    );

    // send email verification
    on<AuthEventSendEmailVerification>(
      (event, emit) async {
        await provider.sendEmailVerification();
        emit(state);
      },
    );

    // register
    on<AuthEventRegister>(
      (event, emit) async {
        final email = event.email;
        final password = event.password;
        try {
          await provider.createUser(
            email: email,
            password: password,
          );
          await provider.sendEmailVerification();
          emit(
            const AuthStateNeedsVerification(
              isLoading: false,
            ),
          );
        } on Exception catch (e) {
          emit(
            AuthStateRegistering(
              exception: e,
              isLoading: false,
            ),
          );
        }
      },
    );

    on<AuthEventShouldRegister>(
      (event, emit) {
        emit(
          const AuthStateRegistering(
            exception: null,
            isLoading: false,
          ),
        );
      },
    );

    // log in
    on<AuthEventShouldLogIn>(
      (event, emit) {
        emit(
          const AuthStateLoggingIn(
            exception: null,
            isLoading: false,
          ),
        );
      },
    );

    on<AuthEventLogIn>(
      (event, emit) async {
        emit(
          const AuthStateLoggedOut(
            exception: null,
            isLoading: true,
            loadingText: 'Please wait a moment',
          ),
        );
        final email = event.email;
        final password = event.password;
        try {
          final user = await provider.logIn(
            email: email,
            password: password,
          );
          // email is not verified so user is not logged in, then emits needs-verification state
          if (!user.isEmailVerified) {
            emit(
              const AuthStateLoggedOut(
                exception: null,
                isLoading: false,
              ),
            );
            emit(
              const AuthStateNeedsVerification(isLoading: false),
            );
          } else {
            emit(
              const AuthStateLoggedOut(
                exception: null,
                isLoading: false,
              ),
            );
            emit(
              AuthStateLoggedIn(
                user: user,
                isLoading: false,
              ),
            );
          }
          // After unsuccessful attempt to log in stays on LoginView
        } on Exception catch (e) {
          emit(
            AuthStateLoggingIn(
              exception: e,
              isLoading: false,
            ),
          );
        }
      },
    );

    // log out
    on<AuthEventLogOut>(
      (event, emit) async {
        try {
          await provider.logOut();
          emit(
            const AuthStateLoggedOut(
              exception: null,
              isLoading: false,
            ),
          );
        } on Exception catch (e) {
          emit(
            AuthStateLoggedOut(
              exception: e,
              isLoading: false,
            ),
          );
        }
      },
    );
  }
}
