import 'package:flutter/material.dart';

Future<String?> showUnsavedChangesDialog({
  required BuildContext context,
  required VoidCallback onSave,
  String title = 'Unsaved Changes',
  String content = 'You have unsaved changes. What would you like to do?',
  String discardLabel = 'DISCARD',
  String cancelLabel = 'CANCEL',
  String saveLabel = 'SAVE',
  Color discardColor = Colors.red,
  Color actionColor = const Color(0xFF002D72),
  required TextStyle titleStyle,
  required TextStyle buttonStyle,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Colors.white,
        title: Text(title, style: titleStyle),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('DISCARD'),
            child: Text(
              discardLabel,
              style: buttonStyle.copyWith(color: discardColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('CANCEL'),
            child: Text(
              cancelLabel,
              style: buttonStyle.copyWith(color: actionColor),
            ),
          ),
          TextButton(
            onPressed: () {
              onSave();
              Navigator.of(context).pop('SAVE');
            },
            child: Text(
              saveLabel,
              style: buttonStyle.copyWith(color: actionColor),
            ),
          ),
        ],
      );
    },
  );
}


