// Flutter imports:
// Package imports:
import 'package:torn_pda/l10n/pda_text.dart';
import 'dart:async';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/drawer.dart';
// Project imports:
import 'package:torn_pda/models/chaining/target_model.dart';
import 'package:torn_pda/models/chat/chat_share_out.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/user_helper.dart';
import 'package:torn_pda/utils/html_parser.dart';
import 'package:torn_pda/widgets/chat/chat_share_widgets.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';
import 'package:torn_pda/widgets/pda_scaffold.dart';

class TargetDetailsPage extends StatefulWidget {
  final TargetModel? target;

  const TargetDetailsPage({required this.target});

  @override
  TargetDetailsPageState createState() => TargetDetailsPageState();
}

class TargetDetailsPageState extends State<TargetDetailsPage> {
  
  late SettingsProvider _settingsProvider;
  late ThemeProvider _themeProvider;

  late StreamSubscription _willPopSubscription;

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    

    routeWithDrawer = false;
    routeName = "target_details";
    _willPopSubscription = _settingsProvider.willPopShouldGoBackStream.stream.listen((event) {
      if (mounted && routeName == "target_details") _goBack();
    });
  }

  @override
  void dispose() {
    _willPopSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context);
    return PdaScaffold(
      appBar: buildAppBar(),
      margin: PdaScaffoldMargin.grey,
      body: Container(
        color: _themeProvider.currentTheme == AppTheme.extraDark ? Colors.black : Colors.transparent,
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${widget.target!.name} [${widget.target!.playerId}]',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: SizedBox(
                          width: 30,
                          height: 30,
                          child: IconButton(
                            icon: const Icon(Icons.content_copy),
                            iconSize: 20,
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: widget.target!.playerId.toString()));
                              BotToast.showText(
                                text: context.interfaceText("Your target's ID [{0}] has been copied to the clipboard!", [widget.target!.playerId]),
                                textStyle: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                                contentColor: Colors.green,
                                duration: const Duration(seconds: 5),
                                contentPadding: const EdgeInsets.all(10),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text('${widget.target!.rank}'),
                  const SizedBox(height: 20),
                  PdaText("Level: {0}", values: [widget.target!.level]),
                  PdaText("Gender: {0}", values: [widget.target!.gender]),
                  PdaText("Age: {0} days", values: [widget.target!.age]),
                  const SizedBox(height: 20),
                  _returnLife(),
                  const SizedBox(height: 5),
                  _returnLastAction(),
                  const SizedBox(height: 5),
                  _returnStatus(),
                  const SizedBox(height: 20),
                  PdaText("Awards: {0} (you have {1})", values: [widget.target!.awards, UserHelper.awards]),
                  const SizedBox(height: 20),
                  PdaText("Donator: {0}", values: [widget.target!.donator == 0 ? 'NO' : 'YES']),
                  PdaText("Friends/Enemies: {0}/{1}", values: [widget.target!.friends, widget.target!.enemies]),
                  const SizedBox(height: 20),
                  _returnFaction(),
                  _returnJob(),
                  _returnDiscord(),
                  _returnCompetition(),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      iconTheme: const IconThemeData(color: Colors.white),
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          _goBack();
        },
      ),
      actions: [
        if (NativeChat.canShare)
          IconButton(
            tooltip: context.interfaceText('Share to chat'),
            icon: const Icon(Icons.forum_outlined),
            onPressed: () => ChatShareIn.shareText(
              ChatShareOut.player(
                name: widget.target!.name ?? '',
                id: widget.target!.playerId ?? 0,
                level: widget.target!.level,
                state: widget.target!.status?.state,
                description: widget.target!.status?.description,
                until: widget.target!.status?.until,
                now: DateTime.now().millisecondsSinceEpoch ~/ 1000,
              ),
            ),
          ),
      ],
    );
  }

  Widget _returnLife() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const SizedBox(
          width: 35,
          child: PdaText('Life'),
        ),
        LinearPercentIndicator(
          padding: const EdgeInsets.all(0),
          barRadius: const Radius.circular(10),
          width: 150,
          lineHeight: 18,
          progressColor: Colors.blue,
          backgroundColor: Colors.grey,
          center: Text(
            '${widget.target!.life!.current}',
            style: const TextStyle(color: Colors.black),
          ),
          percent: widget.target!.life!.current! / widget.target!.life!.maximum! > 1.0
              ? 1.0
              : widget.target!.life!.current! / widget.target!.life!.maximum!,
        ),
        if (widget.target!.status!.state == "Hospital")
          const Icon(
            Icons.local_hospital,
            size: 20,
            color: Colors.red,
          )
        else
          const SizedBox.shrink(),
      ],
    );
  }

  Widget _returnLastAction() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const PdaText(
          'Last action: ',
        ),
        Text(
          widget.target!.lastAction!.relative == "0 minutes ago" ? context.interfaceText('now') : widget.target!.lastAction!.relative!,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: _returnLastActionColor(widget.target!.lastAction!.status),
              shape: BoxShape.circle,
              border: Border.all(),
            ),
          ),
        ),
      ],
    );
  }

  Color _returnLastActionColor(String? status) {
    switch (status) {
      case 'Online':
        return Colors.green;
      case 'Idle':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _returnStatus() {
    Color? stateColor;
    if (widget.target!.status!.color == 'red') {
      stateColor = Colors.red;
    } else if (widget.target!.status!.color == 'green') {
      stateColor = Colors.green;
    } else if (widget.target!.status!.color == 'blue') {
      stateColor = Colors.blue;
    }

    final Widget stateBall = Padding(
      padding: const EdgeInsets.only(left: 5, right: 3, top: 1),
      child: Container(
        width: 13,
        height: 13,
        decoration: BoxDecoration(color: stateColor, shape: BoxShape.circle, border: Border.all()),
      ),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        PdaText("Status: {0}", values: [widget.target!.status!.state]),
        stateBall,
      ],
    );
  }

  Widget _returnFaction() {
    if (widget.target!.faction!.factionId != 0) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          children: <Widget>[
            PdaText("Faction: {0}", values: [HtmlParser.fix(widget.target!.faction!.factionName)]),
            PdaText("Position: {0}", values: [widget.target!.faction!.position]),
            PdaText("Joined: {0} days ago", values: [widget.target!.faction!.daysInFaction]),
          ],
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _returnJob() {
    if (widget.target!.job!.companyId != 0) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          children: <Widget>[
            PdaText("Company: {0}", values: [HtmlParser.fix(widget.target!.job!.companyName)]),
            PdaText("Position: {0}", values: [widget.target!.job!.job]),
          ],
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _returnDiscord() {
    // Discord was introduced in v1.7.1 for targets, reason why we
    // perform a null check
    if (widget.target!.discord == null) {
      return const SizedBox.shrink();
    }

    if (widget.target!.discord!.discordId == "") {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text('Discord ID'),
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: SizedBox(
              width: 30,
              height: 30,
              child: IconButton(
                icon: const Icon(Icons.content_copy),
                iconSize: 20,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: widget.target!.discord!.discordId!));
                  BotToast.showText(
                    text: context.interfaceText("Your target's Discord ID ({0}) has been copied to the clipboard!", [widget.target!.discord!.discordId]),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    contentColor: Colors.green,
                    duration: const Duration(seconds: 5),
                    contentPadding: const EdgeInsets.all(10),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _returnCompetition() {
    if (widget.target!.competition == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const PdaText(
            'COMPETITION',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (widget.target!.competition!.name != null)
            Text(
              '"${widget.target!.competition!.name}"',
            ),
          if (widget.target!.competition!.attacks != null)
            PdaText(
              "Attacks: {0}", values: [widget.target!.competition!.attacks],
            ),
          if (widget.target!.competition!.image != null)
            PdaText(
              "Image: {0}", values: [widget.target!.competition!.image],
            ),
          if (widget.target!.competition!.score != null)
            PdaText(
              "Score: {0}", values: [widget.target!.competition!.score!.ceil()],
            ),
          if (widget.target!.competition!.team != null)
            PdaText(
              "Team: {0}", values: [widget.target!.competition!.team],
            ),
          if (widget.target!.competition!.text != null)
            PdaText(
              "Text: {0}", values: [widget.target!.competition!.text],
            ),
          if (widget.target!.competition!.total != null)
            PdaText(
              "Total (accumulated): {0}", values: [widget.target!.competition!.total],
            ),
          if (widget.target!.competition!.treatsCollectedTotal != null)
            PdaText(
              "Treats collected: {0}", values: [widget.target!.competition!.treatsCollectedTotal],
            ),
          if (widget.target!.competition!.votes != null)
            PdaText(
              "Votes: {0}", values: [widget.target!.competition!.votes],
            ),
          if (widget.target!.competition!.position != null)
            PdaText(
              "Position: {0}", values: [widget.target!.competition!.position],
            ),
        ],
      ),
    );
  }

  void _goBack() {
    routeWithDrawer = true;
    routeName = "chaining_targets";
    Navigator.of(context).pop();
  }
}
