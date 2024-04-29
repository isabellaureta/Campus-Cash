import 'package:expenses_tracker/auth/bloc/auth_bloc.dart';
import 'package:expenses_tracker/auth/bloc/auth_event.dart';
import 'package:expenses_tracker/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class VerifyEmailView extends StatelessWidget {
  const VerifyEmailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.verify_email_view_title,
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: 30.0,
            vertical: 35.0,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppLocalizations.of(context)!.verify_email_view_main_info,
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: 10.0,
              ),
              Text(
                AppLocalizations.of(context)!.verify_email_view_if_confirmed,
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: 50.0,
              ),
              TextButton(
                onPressed: () {
                  context.read<AuthBloc>().add(
                        const AuthEventSendEmailVerification(),
                      );
                },
                child: Text.rich(
                  TextSpan(
                    children: <TextSpan>[
                      TextSpan(
                        text: AppLocalizations.of(context)!
                            .verify_email_view_not_received,
                        style: const TextStyle(
                          color: Color.fromARGB(255, 75, 75, 75),
                        ),
                      ),
                      TextSpan(
                        text: AppLocalizations.of(context)!
                            .verify_email_view_send_again_text_button,
                        style:
                            TextStyle(color: ColorConstants.dartMainThemeColor),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
              const SizedBox(
                height: 100.0,
              ),
              SizedBox(
                width: 225.0,
                child: FilledButton(
                  onPressed: () {
                    context.read<AuthBloc>().add(
                          const AuthEventShouldLogIn(),
                        );
                  },
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!
                        .verify_email_view_log_in_button,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
