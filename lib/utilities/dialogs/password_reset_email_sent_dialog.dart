import 'dart:developer';
import 'package:campuscash/auth/bloc/auth_bloc.dart';
import 'package:campuscash/auth/bloc/auth_event.dart';
import 'package:campuscash/utilities/dialogs/generic_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Future<void> showPasswordResetSentDialog(BuildContext context) {
  log('Password reset sent!');
  return showGenericDialog(
      context: context,
      title: AppLocalizations.of(context)!.dialog_password_reset,
      content: AppLocalizations.of(context)!.dialog_link_sent,
      optionsBuilder: () => {
            'OK': () {
              context.read<AuthBloc>().add(const AuthEventLogOut());
            }
      });
}
