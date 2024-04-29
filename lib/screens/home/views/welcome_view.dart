import 'package:expenses_tracker/auth/bloc/auth_bloc.dart';
import 'package:expenses_tracker/auth/bloc/auth_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.welcome_view_title,
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 32.0),
        child: Center(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Image.asset(
                    'assets/CampusCash.png',
                    height: 350.0,
                    width: 350.0,
                  ),
                ),
              ),
              const SizedBox(
                height: 25.0,
              ),
              Text(
                AppLocalizations.of(context)!.welcome_view_growly,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const SizedBox(
                height: 25.0,
              ),
              SizedBox(
                width: 300.0,
                child: Text(
                  AppLocalizations.of(context)!.welcome_view_text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 300.0,
                child: Text(
                  AppLocalizations.of(context)!.welcome_view_instructions,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(
                height: 50,
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
                        .welcome_view_login_button_text,
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
                          const AuthEventShouldRegister(),
                        );
                  },
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!
                        .welcome_wiev_register_button_text,
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
    );
  }
}
