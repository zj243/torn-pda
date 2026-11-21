// Flutter imports:
import 'package:torn_pda/l10n/pda_text.dart';
import 'package:flutter/material.dart';

class FactionCrimesWidget extends StatefulWidget {
  final String source;

  const FactionCrimesWidget({
    super.key,
    required this.source,
  });

  @override
  FactionCrimesWidgetState createState() => FactionCrimesWidgetState();
}

class FactionCrimesWidgetState extends State<FactionCrimesWidget> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            widget.source == 'YATA' ? 'images/icons/yata_logo.png' : 'images/icons/tornstats_logo.png',
            height: 18,
          ),
          const SizedBox(width: 8),
          PdaText(
            "Member's NNB source: {0}", values: [widget.source],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
