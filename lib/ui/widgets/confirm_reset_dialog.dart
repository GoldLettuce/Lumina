import 'package:flutter/material.dart';

class ConfirmResetDialog extends StatelessWidget {
  final String title;
  final String content;
  final String cancelText;
  final String confirmText;

  const ConfirmResetDialog({
    super.key,
    required this.title,
    required this.content,
    required this.cancelText,
    required this.confirmText,
  });

  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String content,
    required String cancelText,
    required String confirmText,
  }) {
    return showDialog<bool>(
      context: context,
      builder:
          (ctx) => ConfirmResetDialog(
            title: title,
            content: content,
            cancelText: cancelText,
            confirmText: confirmText,
          ),
    ).then((value) => value == true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          child: Text(cancelText),
          onPressed: () => Navigator.pop(context, false),
        ),
        TextButton(
          child: Text(confirmText),
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    );
  }
}
