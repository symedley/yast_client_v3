import 'dart:ui';
import 'dart:core';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'display_login_status.dart';
import 'saved_app_status.dart';
import 'Model/yast_db.dart';
import 'Model/project_tile.dart';
import 'utilities.dart';

class AllProjectsPanel extends StatefulWidget {
  AllProjectsPanel({Key key, this.title, @required this.theSavedStatus})
      : super(key: key);

  static Color color = Colors.orange[50];
  final String title;
  final SavedAppStatus theSavedStatus;

  @override
  _AllProjectsPanelState createState() => new _AllProjectsPanelState();
}

const int MAXCHARS = 20;

class _AllProjectsPanelState extends State<AllProjectsPanel> {
  _AllProjectsPanelState();

  @override
  Widget build(BuildContext context) {
    return displayLoginStatus(
      savedAppStatus: widget.theSavedStatus,
      context: context,
      child: Container(
        color: AllProjectsPanel.color,
        constraints: BoxConstraints.loose(Size(200.0, 400.0)),
        padding: const EdgeInsets.only(
            left: 8.0, top: 8.0, right: 8.0, bottom: 48.0),
        child: new Scaffold(
          backgroundColor: AllProjectsPanel.color,
          body: new StreamBuilder(
              stream: Firestore.instance
                  .collection(YastDb.DbProjectsTableName)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Text('Loading...');
                debugPrint(
                    "numberof it3ms ${snapshot.data.documents.length});");
                return new ListView.builder(
                    itemCount: snapshot.data.documents.length,
                    padding: const EdgeInsets.all(10.0),
                    itemExtent: 80.0,
                    itemBuilder: (context, index) {
                      DocumentSnapshot ds = snapshot.data.documents[index];
//                      return ExpansionTile(
//                        leading: const Icon(Icons.event_seat),
//                        title: Text(
//                            " ${ds['name']} ${ds['id']}"),
//                        backgroundColor: hexToColor(ds['primaryColor']),
//                        initiallyExpanded: false,
//                        //  onTap: _onProjectTap,
//                      );
                      return
                        ProjectTile(
                          displayString: " ${ds['name']}" ,
                          backgroundColor: hexToColor(ds['primaryColor']),
                          onTap: _onProjectTap,
                      );
                    });
              }),
        ),
      ),
    );
  }

  // Project _currentProject;
  // ignore: unused_field
  String _currentProject;

  /// _onProjectTap - user selects current project to do something with
  void _onProjectTap(String str) {
    setState(() {
      _currentProject = str;
    });
    final snackBar = SnackBar(
        content: Text('Selected project: $str'),
        duration: Duration(seconds: 15),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {
            // Some code to undo the change!
          },
        ));
    Scaffold.of(context).showSnackBar(snackBar);
  }
}
