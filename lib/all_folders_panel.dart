import 'dart:core';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'saved_app_status.dart';
import 'display_login_status.dart';
import 'Model/yast_db.dart';
import 'utilities.dart';

class AllFoldersPanel extends StatefulWidget {
  AllFoldersPanel({Key key, this.title, @required this.theSavedStatus})
      : super(key: key);

  static Color panelBackgroundColor = Colors.grey[200];
  final title;
  final SavedAppStatus theSavedStatus;

  @override
  _AllFoldersPanelState createState() => new _AllFoldersPanelState();

  factory AllFoldersPanel.forDesignTime() {
    return AllFoldersPanel(
        title: 'Title', theSavedStatus: new SavedAppStatus.dummy());
  }
}

class _AllFoldersPanelState extends State<AllFoldersPanel> {
  // ignore: unused_field

  @override
  Widget build(BuildContext context) {
    return displayLoginStatus(
      savedAppStatus: widget.theSavedStatus,
      context: context,
      child: Container(
        color: AllFoldersPanel.panelBackgroundColor,
        constraints: BoxConstraints.tight(Size(200.0, 400.0)),
        padding: const EdgeInsets.only(
            left: 0.0, top: 28.0, right: 0.0, bottom: 48.0),
        child: new Scaffold(
          backgroundColor: AllFoldersPanel.panelBackgroundColor,
          body: new StreamBuilder(
              stream: Firestore.instance
                  .collection(YastDb.DbFoldersTableName)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Text('Loading...');
                return new ListView.builder(
                    itemCount: snapshot.data.documents.length,
//                    padding: const EdgeInsets.all(10.0),
                    //itemExtent: 25.0,
                    itemBuilder: (context, index) {
                      DocumentSnapshot ds = snapshot.data.documents[index];
                      return Material(
//                        shape:  RoundedRectangleBorder(
//                          borderRadius: BorderRadius.all(
//                            Radius.circular(Constants.BORDERRADIUS),
//                          ),
//                        ),
//                        color: hexToColor(ds('primaryColor'), transparency: 0x99000000),
                        color: hexToColor(ds['primaryColor'],
                            transparency: 0x99000000),
//                        borderRadius: BorderRadius.all(
//                            Radius.circular(Constants.BORDERRADIUS)),
                        child: ExpansionTile(
                          title: Text(ds['name']),
                          children: <Widget>[
                            new ListTile(
                              subtitle:
                                  Text('primaryColor: ${ds['primaryColor']}'),
                            )
                          ],
                          backgroundColor: hexToColor(ds['primaryColor'],
                              transparency: 0x88000000),
//                          backgroundColor: Colors.white,
                        ),
                      );
                    });
              }),
        ),
      ),
    );
  }

  // TODO move to a utility class or file
  /// Construct a color from a hex code string, of the format #RRGGBB.
  /// 0x88 is the transparency
//  Color hexToColor(String code, {transparency: int}) {
//    return new Color(int.parse(code.substring(1, 7), radix: 16) +
//        (transparency ??= 0x88000000) - code.length);
//  }
}
