import 'package:campuscash/auth/auth_exceptions.dart';
import 'package:campuscash/auth/bloc/auth_bloc.dart';
import 'package:campuscash/auth/bloc/auth_event.dart';
import 'package:campuscash/auth/bloc/auth_state.dart';
import 'package:campuscash/constants/colors.dart';
import 'package:campuscash/utilities/dialogs/error_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});
  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final TextEditingController _email;
  late final TextEditingController _password;
  bool _obscureText = false;

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    _obscureText = true;
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        if (state is AuthStateLoggedOut) {
          if (state.exception is WrongPasswordAuthException) {
            await showErrorDialog(
              context,
              'The password you entered is incorrect.',
            );
          }
          if (state.exception is UserNotFoundAuthException) {
            await showErrorDialog(
              context,
              'User not found',
            );
          } else if (state.exception is GenericAuthException) {
            await showErrorDialog(
              context,
              'Something went wrong, please try again',
            );
          }
        }
      },
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          body: SingleChildScrollView(
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 35.0),
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                height: MediaQuery.of(context).size.height * 0.75,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Align(
                      alignment: Alignment.topLeft,
                      child: Image.asset(
                        'assets/CampusCash.png',
                        height: 100.0,
                        width: 100.0,
                      ),
                    ),
                    const SizedBox(height: 10,),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        AppLocalizations.of(context)!.login_view_welcome_back,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        AppLocalizations.of(context)!.login_view_text,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w400),
                      ),
                    ),
                    const SizedBox(height: 50.0,),
                    TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      enableSuggestions: false,
                      autocorrect: false,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.email),
                        hintText: AppLocalizations.of(context)!
                            .login_view_email_hintText,
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          borderSide: const BorderSide(
                            color: Colors.grey,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          borderSide: BorderSide(
                            color: ColorConstants.dartMainThemeColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    TextField(
                      controller: _password,
                      obscureText: _obscureText,
                      enableSuggestions: false,
                      autocorrect: false,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                            Icons.no_encryption_gmailerrorred_rounded),
                        hintText: AppLocalizations.of(context)!
                            .login_view_password_hintText,
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          },
                          icon: Icon(
                            _obscureText
                                ? Icons.remove_red_eye
                                : Icons.remove_red_eye_outlined,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          borderSide: const BorderSide(
                            color: Colors.grey,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          borderSide: BorderSide(
                            color: ColorConstants.dartMainThemeColor,
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          context.read<AuthBloc>().add(
                            const AuthEventForgotPassword(),
                          );
                        },
                        child: Text(AppLocalizations.of(context)!
                            .login_view_forgot_password),
                      ),
                    ),
                    const SizedBox(height: 25.0,),
                SizedBox(
                width: 225.0,
                child: FilledButton(
                  onPressed: () async {
                    final email = _email.text.trim();
                    final password = _password.text.trim();

                    if (email.isEmpty || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
                      // Show popup for invalid email
                      await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Invalid Email'),
                          content: const Text('Please enter a valid email address.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                      return;
                    }

                    if (password.isEmpty) {
                      // Show popup for empty password
                      await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Password Required'),
                          content: const Text('Please enter your password.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                      return;
                    }

                    try {
                      // Check if the email exists and handle wrong password
                      await FirebaseAuth.instance.signInWithEmailAndPassword(
                        email: email,
                        password: password,
                      );

                      // Dispatch login event if no exception occurs
                      context.read<AuthBloc>().add(
                        AuthEventLogIn(
                          email,
                          password,
                        ),
                      );
                    } on FirebaseAuthException catch (e) {
                      if (e.code == 'wrong-password') {
                        // Popup for wrong password
                        await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Wrong Password'),
                            content: const Text(
                                'The password you entered is incorrect. Please try again.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      } else if (e.code == 'user-not-found') {
                        // Popup for user not found
                        await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('User Not Found'),
                            content: const Text(
                                'No account found with this email. Please check your email or create a new account.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      } else {
                        // Popup for generic error
                        await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Error'),
                            content: const Text(
                                'Invalid email or password'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      }
                    }
                  },
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.login_view_login_button,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 25.0,),
                    TextButton(
                      onPressed: () {
                        context.read<AuthBloc>().add(
                          const AuthEventShouldRegister(),
                        );
                      },
                      child: Text.rich(
                        TextSpan(
                            text: AppLocalizations.of(context)!
                                .login_view_new_account_part1,
                            style:
                            const TextStyle(
                                color: Color.fromARGB(255, 75, 75, 75)),
                            children: [
                              TextSpan(
                                  text: AppLocalizations.of(context)!
                                      .login_view_new_account_part2,
                                  style: TextStyle(
                                      color: ColorConstants.dartMainThemeColor))
                            ]),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}