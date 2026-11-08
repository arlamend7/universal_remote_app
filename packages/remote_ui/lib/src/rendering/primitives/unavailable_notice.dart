import 'package:flutter/material.dart';

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
  Future<void> _explain(BuildContext context) => showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(reason),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
