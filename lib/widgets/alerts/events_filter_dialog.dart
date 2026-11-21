// Flutter imports:
import 'package:torn_pda/l10n/pda_text.dart';
import 'package:flutter/material.dart';

// Project imports:
import 'package:torn_pda/models/firebase_user_model.dart';
import 'package:torn_pda/utils/firebase_firestore.dart';

class EventsFilterDialog extends StatefulWidget {
  final FirebaseUserModel? userModel;

  const EventsFilterDialog({required this.userModel});

  @override
  EventsFilterDialogState createState() => EventsFilterDialogState();
}

class EventsFilterDialogState extends State<EventsFilterDialog> {
  FirebaseUserModel? _firebaseUserModel;

  @override
  void initState() {
    super.initState();
    _firebaseUserModel = widget.userModel;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const PdaText("Filter out events"),
      content: SingleChildScrollView(
        child: Column(
          children: [
            const PdaText(
              "Choose which type of events you would like to "
              "filter OUT (you won't receive notifications from these).",
              style: TextStyle(
                fontSize: 14,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const PdaText("Organized crimes"),
                  Switch(
                    value: _firebaseUserModel!.eventsFilter.contains('crimes'),
                    onChanged: (value) {
                      if (value) {
                        setState(() {
                          FirestoreHelper().addToEventsFilter('crimes');
                        });
                      } else {
                        setState(() {
                          FirestoreHelper().removeFromEventsFilter('crimes');
                        });
                      }
                    },
                    activeTrackColor: Colors.redAccent[100],
                    activeThumbColor: Colors.red,
                    inactiveThumbColor: Colors.green[100],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const PdaText("Company trains"),
                  Switch(
                    value: _firebaseUserModel!.eventsFilter.contains('trains'),
                    onChanged: (value) {
                      if (value) {
                        setState(() {
                          FirestoreHelper().addToEventsFilter('trains');
                        });
                      } else {
                        setState(() {
                          FirestoreHelper().removeFromEventsFilter('trains');
                        });
                      }
                    },
                    activeTrackColor: Colors.redAccent[100],
                    activeThumbColor: Colors.red,
                    inactiveThumbColor: Colors.green[100],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const PdaText("Racing"),
                  Switch(
                    value: _firebaseUserModel!.eventsFilter.contains('racing'),
                    onChanged: (value) {
                      if (value) {
                        setState(() {
                          FirestoreHelper().addToEventsFilter('racing');
                        });
                      } else {
                        setState(() {
                          FirestoreHelper().removeFromEventsFilter('racing');
                        });
                      }
                    },
                    activeTrackColor: Colors.redAccent[100],
                    activeThumbColor: Colors.red,
                    inactiveThumbColor: Colors.green[100],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const PdaText("Bazaar"),
                  Switch(
                    value: _firebaseUserModel!.eventsFilter.contains('bazaar'),
                    onChanged: (value) {
                      if (value) {
                        setState(() {
                          FirestoreHelper().addToEventsFilter('bazaar');
                        });
                      } else {
                        setState(() {
                          FirestoreHelper().removeFromEventsFilter('bazaar');
                        });
                      }
                    },
                    activeTrackColor: Colors.redAccent[100],
                    activeThumbColor: Colors.red,
                    inactiveThumbColor: Colors.green[100],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const PdaText("Attacks"),
                  Switch(
                    value: _firebaseUserModel!.eventsFilter.contains('attacks'),
                    onChanged: (value) {
                      if (value) {
                        setState(() {
                          FirestoreHelper().addToEventsFilter('attacks');
                        });
                      } else {
                        setState(() {
                          FirestoreHelper().removeFromEventsFilter('attacks');
                        });
                      }
                    },
                    activeTrackColor: Colors.redAccent[100],
                    activeThumbColor: Colors.red,
                    inactiveThumbColor: Colors.green[100],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const PdaText("Revives"),
                  Switch(
                    value: _firebaseUserModel!.eventsFilter.contains('revives'),
                    onChanged: (value) {
                      if (value) {
                        setState(() {
                          FirestoreHelper().addToEventsFilter('revives');
                        });
                      } else {
                        setState(() {
                          FirestoreHelper().removeFromEventsFilter('revives');
                        });
                      }
                    },
                    activeTrackColor: Colors.redAccent[100],
                    activeThumbColor: Colors.red,
                    inactiveThumbColor: Colors.green[100],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const PdaText("Trades"),
                  Switch(
                    value: _firebaseUserModel!.eventsFilter.contains('trades'),
                    onChanged: (value) {
                      if (value) {
                        setState(() {
                          FirestoreHelper().addToEventsFilter('trades');
                        });
                      } else {
                        setState(() {
                          FirestoreHelper().removeFromEventsFilter('trades');
                        });
                      }
                    },
                    activeTrackColor: Colors.redAccent[100],
                    activeThumbColor: Colors.red,
                    inactiveThumbColor: Colors.green[100],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const PdaText("Market sales"),
                  Switch(
                    value: _firebaseUserModel!.eventsFilter.contains('market_sales'),
                    onChanged: (value) {
                      if (value) {
                        setState(() {
                          FirestoreHelper().addToEventsFilter('market_sales');
                        });
                      } else {
                        setState(() {
                          FirestoreHelper().removeFromEventsFilter('market_sales');
                        });
                      }
                    },
                    activeTrackColor: Colors.redAccent[100],
                    activeThumbColor: Colors.red,
                    inactiveThumbColor: Colors.green[100],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const PdaText("Bounty claims"),
                  Switch(
                    value: _firebaseUserModel!.eventsFilter.contains('bounty_claims'),
                    onChanged: (value) {
                      if (value) {
                        setState(() {
                          FirestoreHelper().addToEventsFilter('bounty_claims');
                        });
                      } else {
                        setState(() {
                          FirestoreHelper().removeFromEventsFilter('bounty_claims');
                        });
                      }
                    },
                    activeTrackColor: Colors.redAccent[100],
                    activeThumbColor: Colors.red,
                    inactiveThumbColor: Colors.green[100],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const PdaText("Player referrals"),
                  Switch(
                    value: _firebaseUserModel!.eventsFilter.contains('referrals'),
                    onChanged: (value) {
                      if (value) {
                        setState(() {
                          FirestoreHelper().addToEventsFilter('referrals');
                        });
                      } else {
                        setState(() {
                          FirestoreHelper().removeFromEventsFilter('referrals');
                        });
                      }
                    },
                    activeTrackColor: Colors.redAccent[100],
                    activeThumbColor: Colors.red,
                    inactiveThumbColor: Colors.green[100],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const PdaText("Faction applications"),
                  Switch(
                    value: _firebaseUserModel!.eventsFilter.contains('faction_applications'),
                    onChanged: (value) {
                      if (value) {
                        setState(() {
                          FirestoreHelper().addToEventsFilter('faction_applications');
                        });
                      } else {
                        setState(() {
                          FirestoreHelper().removeFromEventsFilter('faction_applications');
                        });
                      }
                    },
                    activeTrackColor: Colors.redAccent[100],
                    activeThumbColor: Colors.red,
                    inactiveThumbColor: Colors.green[100],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const PdaText("Property rental"),
                  Switch(
                    value: _firebaseUserModel!.eventsFilter.contains('rental'),
                    onChanged: (value) {
                      if (value) {
                        setState(() {
                          FirestoreHelper().addToEventsFilter('rental');
                        });
                      } else {
                        setState(() {
                          FirestoreHelper().removeFromEventsFilter('rental');
                        });
                      }
                    },
                    activeTrackColor: Colors.redAccent[100],
                    activeThumbColor: Colors.red,
                    inactiveThumbColor: Colors.green[100],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 15),
          child: TextButton(
            child: const PdaText("Close"),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        )
      ],
    );
  }
}
