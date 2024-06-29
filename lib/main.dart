import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:campuscash/firebase_options.dart';
import 'package:campuscash/screens/home/views/home_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'app_view.dart';
import 'simpleBlocObserver.dart';


import 'package:campuscash/auth/bloc/auth_bloc.dart';
import 'package:campuscash/auth/bloc/auth_event.dart';
import 'package:campuscash/auth/bloc/auth_state.dart';
import 'package:campuscash/auth/firebase_auth_provider.dart';
import 'package:campuscash/helpers/loading_screen.dart';
import 'package:campuscash/screens/home/views/forgot_password_view.dart';
//import 'package:campuscash/views/history_view.dart';
import 'package:campuscash/screens/home/views/login_view.dart';
//import 'package:campuscash/views/bottom_navbar_view.dart';
//import 'package:campuscash/views/user_details_view.dart';
import 'package:campuscash/screens/home/views/register_view.dart';
import 'package:campuscash/screens/home/views/verify_email_view.dart';
import 'package:campuscash/screens/home/views/welcome_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  Bloc.observer = SimpleBlocObserver();
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MyAppView();
  }
}


class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    context.read<AuthBloc>().add(const AuthEventInitialize());
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.isLoading) {
          LoadingScreen().show(
            context: context,
            text: state.loadingText ??
                AppLocalizations.of(context)!.auth_state_loading_text,
          );
        } else {
          LoadingScreen().hide();
        }
      },
      builder: (context, state) {
        if (state is AuthStateLoggedIn) {
          return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
            future: _getUserDetails(state.user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                final userDetailsDoc = snapshot.data;

                if (userDetailsDoc != null) {
                  final firstTime = userDetailsDoc['firstTime'] ?? true;
                  log('firstTime: $firstTime');

                  if (!firstTime) {
                    return const HomeScreen();
                  }
                }

                return const HomeScreen();
              }
            },
          );
        } else if (state is AuthStateLoggingIn) {
          return const LoginView();
        } else if (state is AuthStateNeedsVerification) {
          return const VerifyEmailView();
        } else if (state is AuthStateLoggedOut) {
          return const WelcomeView();
        } else if (state is AuthStateForgotPassword) {
          return const ForgotPasswordView();
        } else if (state is AuthStateRegistering) {
          return const RegisterView();
        } else {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      },
    );
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> _getUserDetails(String userId) async {
    final DocumentSnapshot<Map<String, dynamic>> doc =
    await FirebaseFirestore.instance.collection('userDetails').doc(userId).get();

    if (doc.exists) {
      return doc;
    } else {
      return null;
    }
  }
}