import 'package:flutter/material.dart';

import '../../widgets/sheets/show_app_sheet.dart';

class UnavailableNotice extends StatelessWidget {
  const UnavailableNotice({
    super.key,
    required this.title,
    required this.reason,
  });
  final String title, reason;
  @override
  Widget build(BuildContext context) => Tooltip(
    message: reason,
    child: TextButton(
      onPressed: () => _explain(context),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline, size: 20),
          Flexible(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    ),
  );
  Future<void> _explain(BuildContext context) =>
      showAppSheet<void>(context, title: title, child: Text(reason));
}
