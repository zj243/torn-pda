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
import 'package:torn_pda/providers/api/api_v1_calls.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/user_helper.dart';
import 'package:torn_pda/utils/html_parser.dart';
import 'package:torn_pda/widgets/chat/chat_share_widgets.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

class MemberDetailsPage extends StatefulWidget {
  final String memberId;

  const MemberDetailsPage({required this.memberId});

  @override
  MemberDetailsPageState createState() => MemberDetailsPageState();
}

class MemberDetailsPageState extends State<MemberDetailsPage> {
  
  late SettingsProvider _settingsProvider;
  late ThemeProvider _themeProvider;

  Future? _memberFetched;
  TargetModel? _member;

  late StreamSubscription _willPopSubscription;

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    
    _memberFetched = _fetchMemberDetails();

    routeWithDrawer = false;
    routeName = "member_details";
    _willPopSubscription = _settingsProvider.willPopShouldGoBackStream.stream.listen((event) {
      if (mounted && routeName == "member_details") _goBack();
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
    return FutureBuilder(
      future: _memberFetched,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (_member != null) {
            return Container(
              color: _themeProvider.currentTheme == AppTheme.light
                  ? MediaQuery.orientationOf(context) == Orientation.portrait
                      ? Colors.blueGrey
                      : Colors.grey[900]
                  : _themeProvider.currentTheme == AppTheme.dark
                      ? Colors.grey[900]
                      : Colors.black,
              child: SafeArea(
                child: Scaffold(
                  backgroundColor: _themeProvider.canvas,
                  appBar: _settingsProvider.appBarTop ? buildAppBar() : null,
                  bottomNavigationBar: !_settingsProvider.appBarTop
                      ? SizedBox(
                          height: AppBar().preferredSize.height,
                          child: buildAppBar(),
                        )
                      : null,
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
                                    '${_member!.name} [${_member!.playerId}]',
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
                                          Clipboard.setData(ClipboardData(text: _member!.playerId.toString()));
                                          BotToast.showText(
                                            text: context.interfaceText("Your target's ID [{0}] has been copied to the clipboard!", [_member!.playerId]),
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
                              Text('${_member!.rank}'),
                              const SizedBox(height: 20),
                              PdaText("Level: {0}", values: [_member!.level]),
                              PdaText("Gender: {0}", values: [_member!.gender]),
                              PdaText("Age: {0} days", values: [_member!.age]),
                              const SizedBox(height: 20),
                              _returnLife(),
                              const SizedBox(height: 5),
                              _returnLastAction(),
                              const SizedBox(height: 5),
                              _returnStatus(),
                              const SizedBox(height: 20),
                              PdaText("Awards: {0} (you have {1})", values: [_member!.awards, UserHelper.awards]),
                              const SizedBox(height: 20),
                              PdaText("Donator: {0}", values: [_member!.donator == 0 ? 'NO' : 'YES']),
                              PdaText("Friends/Enemies: {0}/{1}", values: [_member!.friends, _member!.enemies]),
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
                ),
              ),
            );
          } else {
            return const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(height: 50),
                PdaText(
                  'OOPS!',
                  style: TextStyle(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  child: Column(
                    children: [
                      PdaText(
                        "There was a problem getting this member's profile, please try again later!",
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 50),
              ],
            );
          }
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
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
        if (NativeChat.canShare && _member != null)
          IconButton(
            tooltip: context.interfaceText('Share to chat'),
            icon: const Icon(Icons.forum_outlined),
            onPressed: () => ChatShareIn.shareText(
              ChatShareOut.player(
                name: _member!.name ?? '',
                id: _member!.playerId ?? 0,
                level: _member!.level,
                state: _member!.status?.state,
                description: _member!.status?.description,
                until: _member!.status?.until,
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
            '${_member!.life!.current}',
            style: const TextStyle(color: Colors.black),
          ),
          percent: _member!.life!.current! / _member!.life!.maximum! > 1.0
              ? 1.0
              : _member!.life!.current! / _member!.life!.maximum!,
        ),
        if (_member!.status!.state == "Hospital")
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
          _member!.lastAction!.relative == "0 minutes ago" ? 'now' : _member!.lastAction!.relative!,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: _returnLastActionColor(_member!.lastAction!.status),
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
    if (_member!.status!.color == 'red') {
      stateColor = Colors.red;
    } else if (_member!.status!.color == 'green') {
      stateColor = Colors.green;
    } else if (_member!.status!.color == 'blue') {
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
        PdaText("Status: {0}", values: [_member!.status!.state]),
        stateBall,
      ],
    );
  }

  Widget _returnFaction() {
    if (_member!.faction!.factionId != 0) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          children: <Widget>[
            PdaText("Faction: {0}", values: [HtmlParser.fix(_member!.faction!.factionName)]),
            PdaText("Position: {0}", values: [_member!.faction!.position]),
            PdaText("Joined: {0} days ago", values: [_member!.faction!.daysInFaction]),
          ],
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _returnJob() {
    if (_member!.job!.companyId != 0) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          children: <Widget>[
            PdaText("Company: {0}", values: [HtmlParser.fix(_member!.job!.companyName)]),
            PdaText("Position: {0}", values: [_member!.job!.job]),
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
    if (_member!.discord == null) {
      return const SizedBox.shrink();
    }

    if (_member!.discord!.discordId == "") {
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
                  Clipboard.setData(ClipboardData(text: _member!.discord!.discordId!));
                  BotToast.showText(
                    text: context.interfaceText("Your target's Discord ID ({0}) has been copied to the clipboard!", [_member!.discord!.discordId]),
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
    if (_member!.competition == null) {
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
          if (_member!.competition!.name != null)
            Text(
              '"${_member!.competition!.name}"',
            ),
          if (_member!.competition!.attacks != null)
            PdaText(
              "Attacks: {0}", values: [_member!.competition!.attacks],
            ),
          if (_member!.competition!.image != null)
            PdaText(
              "Image: {0}", values: [_member!.competition!.image],
            ),
          if (_member!.competition!.score != null)
            PdaText(
              "Score: {0}", values: [_member!.competition!.score!.ceil()],
            ),
          if (_member!.competition!.team != null)
            PdaText(
              "Team: {0}", values: [_member!.competition!.team],
            ),
          if (_member!.competition!.text != null)
            PdaText(
              "Text: {0}", values: [_member!.competition!.text],
            ),
          if (_member!.competition!.total != null)
            PdaText(
              "Total (accumulated): {0}", values: [_member!.competition!.total],
            ),
          if (_member!.competition!.treatsCollectedTotal != null)
            PdaText(
              "Treats collected: {0}", values: [_member!.competition!.treatsCollectedTotal],
            ),
          if (_member!.competition!.votes != null)
            PdaText(
              "Votes: {0}", values: [_member!.competition!.votes],
            ),
          if (_member!.competition!.position != null)
            PdaText(
              "Position: {0}", values: [_member!.competition!.position],
            ),
        ],
      ),
    );
  }

  Future _fetchMemberDetails() async {
    final dynamic myNewTargetModel = await ApiCallsV1.getTarget(playerId: widget.memberId);

    if (myNewTargetModel is TargetModel) {
      _member = myNewTargetModel;
      return;
    }
  }

  void _goBack() {
    routeWithDrawer = true;
    routeName = "chaining_war";
    Navigator.of(context).pop();
  }
}
