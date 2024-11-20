import 'package:campuscash/auth/bloc/auth_event.dart';
import 'package:campuscash/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:campuscash/auth/bloc/auth_bloc.dart';
import 'package:campuscash/auth/bloc/auth_state.dart';
import 'package:campuscash/utilities/dialogs/error_dialog.dart';
import 'package:campuscash/utilities/dialogs/password_reset_email_sent_dialog.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});
  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  late final TextEditingController _textController;
  @override
  void initState() {
    _textController = TextEditingController();
    super.initState();
  }
  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        if (state is AuthStateForgotPassword) {
          if (state.hasSentEmail) {
            _textController.clear();
            await showPasswordResetSentDialog(context);
          }
          if (state.exception != null) {
            await showErrorDialog(
              context,
              AppLocalizations.of(context)!.forgot_password_view_dialog_context,
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
                margin: const EdgeInsets.symmetric(
                  horizontal: 30.0,
                  vertical: 35.0,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                ),
                height: MediaQuery.of(context).size.height * 0.75,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Align(
                      alignment: Alignment.topLeft,
                      child: Image.asset(
                        'assets/main_menu_icon.png',
                        height: 100.0,
                        width: 100.0,
                      ),
                    ),
                    const SizedBox(
                      height: 10.0,
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        AppLocalizations.of(context)!
                            .forgot_password_view_forgot_password,
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        AppLocalizations.of(context)!
                            .forgot_password_view_dont_worry,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 50.0,
                    ),
                    Text(
                      AppLocalizations.of(context)!
                          .forgot_password_view_provide_email,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(
                      height: 10.0,
                    ),
                    TextField(
                      controller: _textController,
                      keyboardType: TextInputType.emailAddress,
                      enableSuggestions: false,
                      autocorrect: false,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.email),
                        hintText: AppLocalizations.of(context)!
                            .forgot_password_view_email_hintText,
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          borderSide: BorderSide(
                            color: ColorConstants.dartMainThemeColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 25.0,
                    ),
                    SizedBox(
                      width: 225.0,
                      child: FilledButton(
                        onPressed: () async {
                          final email = _textController.text;
                          context
                              .read<AuthBloc>()
                              .add(AuthEventForgotPassword(email: email));
                        },
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!
                              .forgot_password_view_send_button,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 225.0,
                      child: FilledButton.tonal(
                        onPressed: () {
                          context.read<AuthBloc>().add(
                                const AuthEventLogOut(),
                              );
                        },
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!
                              .forgot_password_view_back_button,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 75.0,
                    )
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
