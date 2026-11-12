import 'package:flutter/material.dart';

String journeyText(BuildContext context, String english, String portuguese) {
  final locale = Localizations.maybeLocaleOf(context);
  final platform = View.of(context).platformDispatcher.locale;
  return locale?.languageCode == 'pt' || platform.languageCode == 'pt'
      ? portuguese
      : english;
}
