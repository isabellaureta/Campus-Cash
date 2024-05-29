import 'package:flutter/material.dart';
import 'package:campuscash/utilities/dialogs/generic_dialog.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Future<void> showErrorDialog(
  BuildContext context,
  String text,
) {
  return showGenericDialog<void>(
    context: context,
    title: AppLocalizations.of(context)!.dialog_error,
    content: text,
    optionsBuilder: () => {
      'OK': null,
    },
  );
}
