import 'package:expenses_tracker/utilities/dialogs/generic_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Future<bool> showLogOutDialog(BuildContext context) {
  return showGenericDialog(
    context: context,
    title: AppLocalizations.of(context)!.dialog_logging_out,
    content: AppLocalizations.of(context)!.dialog_are_you_sure_logout,
    optionsBuilder: () => {
      AppLocalizations.of(context)!.dialog_cancel: false,
      AppLocalizations.of(context)!.dialog_logout: true,
    },
  ).then(
    (value) => value ?? false,
  );
}
