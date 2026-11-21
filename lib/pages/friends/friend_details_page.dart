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
import 'package:torn_pda/models/friends/friend_model.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/user_helper.dart';
import 'package:torn_pda/utils/html_parser.dart';
import 'package:torn_pda/widgets/pda_scaffold.dart';

class FriendDetailsPage extends StatefulWidget {
  final FriendModel? friend;

  const FriendDetailsPage({required this.friend});

  @override
  FriendDetailsPageState createState() => FriendDetailsPageState();
}

class FriendDetailsPageState extends State<FriendDetailsPage> {
  
  late SettingsProvider _settingsProvider;
  late ThemeProvider _themeProvider;

  late StreamSubscription _willPopSubscription;

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    

    routeWithDrawer = false;
    routeName = "friend_details";
    _willPopSubscription = _settingsProvider.willPopShouldGoBackStream.stream.listen((event) {
      if (mounted && routeName == "friend_details") _goBack();
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
                        '${widget.friend!.name} [${widget.friend!.playerId}]',
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
                              Clipboard.setData(ClipboardData(text: widget.friend!.playerId.toString()));
                              BotToast.showText(
                                text: context.interfaceText("Your friend's ID [{0}] has been copied to the clipboard!", [widget.friend!.playerId]),
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
                  Text('${widget.friend!.rank}'),
                  const SizedBox(height: 20),
                  PdaText("Level: {0}", values: [widget.friend!.level]),
                  PdaText("Gender: {0}", values: [widget.friend!.gender]),
                  PdaText("Age: {0} days", values: [widget.friend!.age]),
                  const SizedBox(height: 20),
                  _returnLife(),
                  const SizedBox(height: 5),
                  _returnLastAction(),
                  const SizedBox(height: 5),
                  _returnStatus(),
                  const SizedBox(height: 20),
                  PdaText("Awards: {0} (you have {1})", values: [widget.friend!.awards, UserHelper.awards]),
                  const SizedBox(height: 20),
                  PdaText("Donator: {0}", values: [widget.friend!.donator == 0 ? 'NO' : 'YES']),
                  PdaText("Friends/Enemies: {0}/{1}", values: [widget.friend!.friends, widget.friend!.enemies]),
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
      title: Text('${widget.friend!.name}'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          _goBack();
        },
      ),
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
            '${widget.friend!.life!.current}',
            style: const TextStyle(color: Colors.black),
          ),
          percent: widget.friend!.life!.current! / widget.friend!.life!.maximum! > 1.0
              ? 1.0
              : widget.friend!.life!.current! / widget.friend!.life!.maximum!,
        ),
        if (widget.friend!.status!.state == "Hospital")
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
          widget.friend!.lastAction!.relative == "0 minutes ago" ? 'now' : widget.friend!.lastAction!.relative!,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: _returnLastActionColor(widget.friend!.lastAction!.status),
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
    if (widget.friend!.status!.color == 'red') {
      stateColor = Colors.red;
    } else if (widget.friend!.status!.color == 'green') {
      stateColor = Colors.green;
    } else if (widget.friend!.status!.color == 'blue') {
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
        PdaText("Status: {0}", values: [widget.friend!.status!.state]),
        stateBall,
      ],
    );
  }

  Widget _returnFaction() {
    if (widget.friend!.faction!.factionId != 0) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          children: <Widget>[
            PdaText("Faction: {0}", values: [HtmlParser.fix(widget.friend!.faction!.factionName)]),
            PdaText("Position: {0}", values: [widget.friend!.faction!.position]),
            PdaText("Joined: {0} days ago", values: [widget.friend!.faction!.daysInFaction]),
          ],
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _returnJob() {
    if (widget.friend!.job!.companyId != 0) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          children: <Widget>[
            PdaText("Company: {0}", values: [HtmlParser.fix(widget.friend!.job!.companyName)]),
            PdaText("Position: {0}", values: [widget.friend!.job!.job]),
          ],
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _returnDiscord() {
    if (widget.friend!.discord!.discordId != "") {
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
                    Clipboard.setData(ClipboardData(text: widget.friend!.discord!.discordId!));
                    BotToast.showText(
                      text: context.interfaceText("Your friend's Discord ID ({0}) has been copied to the clipboard!", [widget.friend!.discord!.discordId]),
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
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _returnCompetition() {
    if (widget.friend!.competition == null) {
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
          if (widget.friend!.competition!.name != null)
            Text(
              '"${widget.friend!.competition!.name}"',
            ),
          if (widget.friend!.competition!.attacks != null)
            PdaText(
              "Attacks: {0}", values: [widget.friend!.competition!.attacks],
            ),
          if (widget.friend!.competition!.image != null)
            PdaText(
              "Image: {0}", values: [widget.friend!.competition!.image],
            ),
          if (widget.friend!.competition!.score != null)
            PdaText(
              "Score: {0}", values: [widget.friend!.competition!.score!.ceil()],
            ),
          if (widget.friend!.competition!.team != null)
            PdaText(
              "Team: {0}", values: [widget.friend!.competition!.team],
            ),
          if (widget.friend!.competition!.text != null)
            PdaText(
              "Text: {0}", values: [widget.friend!.competition!.text],
            ),
          if (widget.friend!.competition!.total != null)
            PdaText(
              "Total (accumulated): {0}", values: [widget.friend!.competition!.total],
            ),
          if (widget.friend!.competition!.treatsCollectedTotal != null)
            PdaText(
              "Treats collected: {0}", values: [widget.friend!.competition!.treatsCollectedTotal],
            ),
          if (widget.friend!.competition!.votes != null)
            PdaText(
              "Votes: {0}", values: [widget.friend!.competition!.votes],
            ),
          if (widget.friend!.competition!.position != null)
            PdaText(
              "Position: {0}", values: [widget.friend!.competition!.position],
            ),
        ],
      ),
    );
  }

  void _goBack() {
    routeWithDrawer = true;
    routeName = "friends";
    Navigator.of(context).pop();
  }
}
