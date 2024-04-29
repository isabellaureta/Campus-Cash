import 'package:expenses_tracker/utilities/dialogs/generic_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Future<bool> showDeleteTransactionDialog(BuildContext context) {
  return showGenericDialog(
    context: context,
    title: AppLocalizations.of(context)!.dialog_delete,
    content: AppLocalizations.of(context)!.dialog_are_you_sure_transaction,
    optionsBuilder: () => {
      AppLocalizations.of(context)!.dialog_cancel: false,
      AppLocalizations.of(context)!.dialog_delete: true,
    },
  ).then(
    (value) => value ?? false,
  );
}
