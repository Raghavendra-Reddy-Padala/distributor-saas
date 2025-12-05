import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CopyableText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextOverflow? overflow;
  final Duration snackDuration;
  final String copiedMessage; // message shown in SnackBar

  const CopyableText({
    Key? key,
    required this.text,
    this.style,
    this.overflow,
    this.snackDuration = const Duration(seconds: 1),
    this.copiedMessage = 'Copied',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: text));
        final snack = SnackBar(
          content: Text('$copiedMessage: $text'),
          duration: snackDuration,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        );
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(snack);
      },
      child: Text(
        text,
        style: style,
        overflow: overflow,
      ),
    );
  }
}
