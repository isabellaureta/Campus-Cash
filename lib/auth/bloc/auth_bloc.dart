import 'package:bloc/bloc.dart';
import 'package:campuscash/auth/auth_provider.dart';
import 'package:campuscash/auth/bloc/auth_event.dart';
import 'package:campuscash/auth/bloc/auth_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

Future<Map<String, dynamic>> fetchUserData(String userId) async {
  try {
    final userDocument = FirebaseFirestore.instance.collection('users').doc(userId);
    final userData = await userDocument.get();
    if (!userData.exists) {
      throw Exception('User data not found');
    }
    return userData.data() ?? {};
  } on FirebaseException catch (e) {
    if (e.code == 'permission-denied') {
      debugPrint('Permission denied: ${e.message}');
      throw Exception('You do not have permission to access this data.');
    } else {
      debugPrint('Error fetching user data: ${e.message}');
      throw Exception('Error fetching user data.');
    }
  }
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(AuthProvider provider)
      : super(const AuthStateUninitialized(isLoading: true)) {
    on<AuthEventInitialize>((event, emit) async {
      await provider.initialize();
      final user = provider.currentUser;
      if (user == null) {
        emit(const AuthStateLoggedOut(exception: null, isLoading: false));
      } else if (!user.isEmailVerified) {
        emit(const AuthStateNeedsVerification(isLoading: false));
      } else {
        try {
          final userData = await fetchUserData(user.uid);
          emit(AuthStateLoggedIn(user: user, userData: userData, isLoading: false));
        } on Exception catch (e) {
          emit(AuthStateLoggedOut(exception: e, isLoading: false));
        }
      }
    });

    on<AuthEventForgotPassword>((event, emit) async {
      emit(
        const AuthStateForgotPassword(
          exception: null,
          hasSentEmail: false,
          isLoading: false,
        ),
      );
      final email = event.email;
      if (email == null) {
        return;
      }
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
    });
    on<AuthEventSendEmailVerification>((event, emit) async {
      await provider.sendEmailVerification();
      emit(state);
    });
    on<AuthEventRegister>((event, emit) async {
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
    });

    on<AuthEventShouldRegister>((event, emit) {
      emit(
        const AuthStateRegistering(
          exception: null,
          isLoading: false,
        ),
      );
    });

    on<AuthEventShouldLogIn>((event, emit) {
      emit(
        const AuthStateLoggingIn(
          exception: null,
          isLoading: false,
        ),
      );
    });

    on<AuthEventLogIn>((event, emit) async {
      emit(const AuthStateLoggedOut(exception: null, isLoading: true, loadingText: 'Please wait a moment'));
      final email = event.email;
      final password = event.password;
      try {
        final user = await provider.logIn(email: email, password: password);
        if (!user.isEmailVerified) {
          emit(const AuthStateLoggedOut(exception: null, isLoading: false));
          emit(const AuthStateNeedsVerification(isLoading: false));
        } else {
          try {
            final userData = await fetchUserData(user.uid);
            emit(AuthStateLoggedIn(user: user, userData: userData, isLoading: false));
          } on Exception catch (e) {
            emit(AuthStateLoggedOut(exception: e, isLoading: false));
          }
        }
      } on Exception catch (e) {
        emit(AuthStateLoggingIn(exception: e, isLoading: false));
      }
    });

    on<AuthEventLogOut>((event, emit) async {
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
    });
  }
}
