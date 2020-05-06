import 'dart:core';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'yast_db.dart';
import '../constants.dart';
import 'project.dart';

Future<Map<String,Project>>getProjectIdMapFromDb() async {
  Map idToProjectName = new Map<String, Project>();
  try {
    WriteBatch batch = Firestore.instance.batch();
    QuerySnapshot qs = await Firestore.instance
        .collection(YastDb.DbProjectsTableName)
        .getDocuments();

    // TODO this will have to be like getYastObjectsFromXml.
    qs.documents.forEach((DocumentSnapshot doc) {
//      Project obj =
//      idToProjectName
//          .addAll({doc.data['id']: doc.data['name']}.cast<String, Project>());
      DocumentReference dr =
          Firestore.instance.document('/${YastDb.DbIdToProjectTableName}/${doc.data["id"]}');
      batch.setData(dr, {doc.data['id']: doc.data['name']});
    });

    await batch
        .commit()
        .timeout(Duration(seconds: Constants.HTTP_TIMEOUT))
        .then((it) {
      debugPrint('id to project map batch result ???');
    }).whenComplete(() {
      debugPrint('id to project map batch complete');
    });
  } catch (e) {
    print('Failed to retrieve projects from db and creat  id name map');
    print(e);
  }
  return idToProjectName;
}
