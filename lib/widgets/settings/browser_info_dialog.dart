// Flutter imports:
import 'package:torn_pda/l10n/pda_text.dart';
import 'package:flutter/material.dart';

class BrowserInfoDialog extends StatefulWidget {
  @override
  BrowserInfoDialogState createState() => BrowserInfoDialogState();
}

class BrowserInfoDialogState extends State<BrowserInfoDialog> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const PdaText("Browser type"),
      content: const SingleChildScrollView(
        child: Column(
          children: [
            PdaText("Choosing the in-app browser "
                "offers a better experience and additional "
                "features, such as foreign stock uploading "
                "to a common database in YATA that everyone "
                "benefits from."
                "\n\n"
                "Please consider using it, unless you "
                "have issues, in which case you can select "
                "you mobile phone's default browser (external)."),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const PdaText("Close"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        )
      ],
    );
  }
}
