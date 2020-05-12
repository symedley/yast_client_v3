import 'dart:async';
import 'package:flutter/material.dart';
import 'package:xml/xml.dart' as xml;
import 'Model/record.dart';
import 'Model/yast_db.dart';
import 'Model/project.dart';
import 'Model/folder.dart';
import 'Model/yast_object.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'constants.dart';

enum TypeXmlObject {
  Project,
  Folder,
  Record,
}

const String projectStr = 'project'; //plural
const String folderStr = 'folder';
const String recordStr = 'record';

/// Create Folders from the XML
Future<Map<String, String>> getFoldersFrom(xml.XmlDocument xmlBody) async {
  debugPrint('-------------********** _getFoldersFrom');

  List<xml.XmlElement> xmlObjs = await _getXmlObjectsFrom(xmlBody, folderStr);
  Map<String, Folder> mapFolderIdName = new Map();
  var retval = await _getYastObjectsFromXmlAndStoreInDb(
      mapFolderIdName, TypeXmlObject.Folder, xmlObjs);
  debugPrint('-------------**********END  _getFoldersFrom');
  return retval;
}

/// Create Projects from the XML
Future<Map<String, Project>> getProjectsFrom(xml.XmlDocument xmlBody) async {
  List<xml.XmlElement> xmlObjs = _getXmlObjectsFrom(xmlBody, projectStr);
  Map<String, Project> mapProjects = new Map();
  return await _getYastObjectsFromXmlAndStoreInDb(
      mapProjects, TypeXmlObject.Project, xmlObjs);
}

/// _getXmlObjectsFrom gets Projects or Folders out of this
/// Xml element. The element must be named folder or project
/// and its children are the items of that type.
List<xml.XmlElement> _getXmlObjectsFrom(
    xml.XmlDocument xmlBody, String objType) {
  Iterable iterable = xmlBody.findAllElements(objType).map((obj) {
    return obj;
  });
  List<xml.XmlElement> xmlObjectList = new List<xml.XmlElement>();
  iterable.forEach((dynamic it) {
    xmlObjectList.add(it);
  });
  return xmlObjectList;
}

///getRecordsFrom
///
// id(optional): Comma separated list of requested record identifiers
//  user(required): Yast user
//  hash(required): Yast user hash
//  parentId(optional) : Comma separated list of Ids of the project requested records belong to.
//  typeId(optional) : Id of the recordType object describing this record
//  timeFrom(optional) : Time of creation [seconds since 1st of January 1970]
//  timeTo(optional) : Time of last update [seconds since 1st of January 1970]
//  userId(optional) : Only relevant for usage through Entity API as Organization. Comma separated list of user identifiers for requested records
//
//  Work Record
//  A record is a work record if the typeId field is 1. A work record has the following variables in the variables array :
//
//  startTime : Start-time of record [seconds since 1st of January 1970]
//  endTime : End-time of record [seconds since 1st of January 1970]
//  comment : String with comment for record
//  isRunning : 1 if the record is running. In that case endTime has not been set yet. Else 0
///getRecordsFrom
///
Future<Map<String, Record>> getRecordsFrom(xml.XmlDocument xmlBody) async {
  //return _getXmlObjectsFrom(xmlBody, "record");
  debugPrint('==========_getRecordsFrom');
  List<xml.XmlElement> xmlObjs = _getXmlObjectsFrom(xmlBody, "record");
  if (null != YastDb.LIMITCOUNTOFRECORDS) {
    xmlObjs.length = YastDb.LIMITCOUNTOFRECORDS;
  }
  Map<String, Record> recs = new Map<String, Record>();
  xmlObjs.forEach((it) {
    Record aRec = new Record.fromXml(it);
    recs[aRec.id] = aRec;
  });
  // This could return the recs before putting them in database.
  // I guess that's okay, but what if i needed to wait?
  // It complains if I try to await _putRecordsInDatabase
//  await putRecordsInDatabase(recs);
  return recs;
} //_getRecordsFrom

Future<void> putRecordsInDatabase(Map<String, Record> recs,
    {bool selectivelyDelete = false}) async {
  // Variable block of the yast.com xml response:
  // Take the things in the variables block
  // that were pulled out in making the Record
  // object and put into the fieldsMap of the
  // Record object as well as the appropriate
  // fields of the object. This is to make it easy
  // to put the fields into the Firestore database.

  // Selectively delete the old records and then just add new ones that were retrieved.
  // If the HTTP request to yast.com failed, then we shouldn't get to this point
  // so we won't end up with no records if data connection is lost. (I hope)
  debugPrint('==========_putRecordsInDatabase');

  int counter = 0;
  Set<String> oldKeys;
  if (recs.isNotEmpty)
    oldKeys = await _getKeysOfCollection(YastDb.DbRecordsTableName);
  else
    oldKeys = new Set();

  WriteBatch batch = Firestore.instance.batch();
  recs.values.forEach((rec) async {
    if (((counter % YastDb.BATCHLIMIT) == 0) && (counter != 0)) {
      batch.commit();
      batch = Firestore.instance.batch();
      debugPrint("====mid way store records count: $counter");
    }
    DocumentReference dr =
        Firestore.instance.document('${YastDb.DbRecordsTableName}/${rec.id}');
    batch.setData(dr, rec.yastObjectFieldsMap);
    oldKeys.remove(rec.id);

    counter++;
  });
//  if (true) {
//    await batch.commit().timeout(Duration(seconds: Constants.HTTP_TIMEOUT));
//    debugPrint("====final store records count: $counter");
//  }
  debugPrint("============== total records count: $counter");

  await (((batch
      .commit()
      .timeout(Duration(seconds: Constants.HTTP_TIMEOUT)))))
      .then((void it) {
    debugPrint('records batch result ');
  }).whenComplete(() {
    debugPrint('records batch complete');
  });

  // the new list of records just gotten from yast.com
  if (selectivelyDelete) {
    debugPrint(
        "============== number of record keys to delete: ${oldKeys.length}");
    await selectivelyDeleteFromFirestoreCollection(
        YastDb.DbRecordsTableName, oldKeys);
  }
    debugPrint('hi');
} // _putRecordsInDatabase

/// a List of the keys of the named collection in Firebase Cloud Firestore
Future<Set<String>> _getKeysOfCollection(String collectionName) async {
  debugPrint('-------------**********_getKeysOfCollection');

  Query query = Firestore.instance.collection(collectionName);
  QuerySnapshot qss = await query.getDocuments();
  Set<String> retval = new Set();
  qss.documents.forEach((docSnap) {
    docSnap.data.keys;
    int startchar = 1 + docSnap.reference.path.indexOf('/', 0);
    String id = docSnap.reference.path
        .substring(startchar, docSnap.reference.path.length);
    retval.add(id);
  });
  return retval;
} //_getKeysOfACollection

Future<void> selectivelyDeleteRecordsWithinDateRange(Set<Record> recsToExamine,
    String startTimeStrUtc, String endTimeStrUtc) async {
  Set<String> keysToDelete = new Set();
  recsToExamine.forEach((Record rec) {
    if ((startTimeStrUtc.compareTo(rec.startTimeStr) > 0) &&
        (endTimeStrUtc.compareTo(rec.startTimeStr) < 0)) {
      keysToDelete.add(rec.id);
    }
  });
  await selectivelyDeleteFromFirestoreCollection(
      YastDb.DbRecordsTableName, keysToDelete);
}

/// Delete only records matching these keys from the named Firestore collection
Future<void> selectivelyDeleteFromFirestoreCollection(
    String collectionName, Set<String> theTargets) async {
  int counter = 0;
  try {
    WriteBatch batch = Firestore.instance.batch();
    theTargets.forEach((String key) {
      if (((counter % YastDb.BATCHLIMIT) == 0) && (counter > 0)) {
        batch.commit();
        batch = Firestore.instance.batch();
        debugPrint("====mid way DELETE records count: $counter");
      }
      DocumentReference dr =
          Firestore.instance.document('${YastDb.DbRecordsTableName}/$key');
      batch.delete(dr);

      counter++;
    });
  await (batch
      .commit()
      .timeout(Duration(seconds: Constants.HTTP_TIMEOUT)) )
      .then((void it) {
    debugPrint('records batch result ');
  }).whenComplete(() {
    debugPrint('records batch complete');
  });
    await batch.commit().timeout(Duration(seconds: Constants.HTTP_TIMEOUT));
  } on UnsupportedError catch (e) {
    debugPrint("Error deleting records from Firestore $e");
  }
}

/// Brute force delete all documents in a collection of the given name.
/// A utility function.
Future<void> _deleteAllDocsInCollection(String collectionName) async {
  debugPrint('-------------**********_deleteAllDocsInCollection');
  // stuff, we want to continue on.
  try {
    Query query = Firestore.instance.collection(collectionName);
    int counter = 0;
    WriteBatch batchDelete = Firestore.instance.batch();
    QuerySnapshot qss = await query.getDocuments();
    qss.documents.forEach((snap) async {
      if ((counter % YastDb.BATCHLIMIT) == 0) {
        batchDelete.commit();
        batchDelete = Firestore.instance.batch();
        debugPrint("====mid way deletion count: $counter");
      }
      if (collectionName == 'folders') {
        debugPrint('-------------**********these docs are folders');

        Query querySubCollections = await snap.reference.collection('children');
        QuerySnapshot subcollectionSnap =
        await querySubCollections.getDocuments();
        subcollectionSnap.documents.forEach((subSnap) async {
          await subSnap.reference.delete();
        });
      }
      batchDelete.delete(snap.reference);
      counter++;
    });
    batchDelete.commit();
    debugPrint("============== _deleteAllDocsInCollection count: $counter");
  } on UnsupportedError catch (e) {
    debugPrint("Error deleting documents from Firestore $e");
  }
} //_deleteAllDocsInCollection

/// Get YastObjects - Projects or Folders, from the colletion
/// of XML objects provided and store in the Firestore database.
/// Most of the logic for retrieving Projects and Folders
/// is the same.
/// NOT for Record objects.
/// Changes mapYastObjects. mapYastObjects is expected (but not required) to be
/// empty when passed in.
/// Returns the Map that was passed in.
Future<Map<String, dynamic>> _getYastObjectsFromXmlAndStoreInDb(
    Map<String, YastObject> mapYastObjects,
    TypeXmlObject whichOne,
    List<xml.XmlElement> xmlObjs) async {
  debugPrint("---------_getYastObjectsFrom");

  String collectionName;
  collectionName = (whichOne == TypeXmlObject.Project)
      ? YastDb.DbProjectsTableName
      : YastDb.DbFoldersTableName;

  Set<String> oldKeys = new Set.from(mapYastObjects.keys);

  xmlObjs.forEach((it) {
    var obj;

    if (whichOne == TypeXmlObject.Folder) {
      obj = new Folder.fromXml(it);
    } else {
      obj = new Project.fromXml(it);
    }
//    mapIdToYastObjects[obj.id] = obj.name;
    mapYastObjects[obj.id] = obj;
    oldKeys.remove(obj.id);
  });
  debugPrint(mapYastObjects.toString());

  // When will there be Projects/Folders to delete from
  // Yast and from the database? When the incoming
  // XML is missing one or more of the Projects/Folders
  // that is in the mapYastObjects.
  selectivelyDeleteFromFirestoreCollection(collectionName, oldKeys);

  WriteBatch batch = Firestore.instance.batch();
  mapYastObjects.values.forEach((obj) async {
    DocumentReference dr = Firestore.instance.document('$collectionName/${obj.id}');
    batch.setData(dr, {
      YastObject.FIELDSMAPID: obj.id,
      YastObject.FIELDSMAPNAME: obj.name,
      YastObject.FIELDSMAPDESCRIPTION: obj.description,
      YastObject.FIELDSMAPPRIMARYCOLOR: obj.primaryColor,
      YastObject.FIELDSMAPPARENTID: obj.parentId,
      YastObject.FIELDSMAPPRIVILEGES: obj.privileges,
      YastObject.FIELDSMAPTIMECREATED: obj.timeCreated,
      YastObject.FIELDSMAPCREATOR: obj.creator,
      YastObject.FIELDSMAPFLAGS: obj.flags,
    });
  });
  await ( batch.commit().timeout(Duration(seconds: 30))).then((void it) {
    debugPrint('batch done ');
  }).whenComplete(() {
    debugPrint('batch complete');
  });
//    if (whichOne == TypeXmlObject.Folder) {
//      await _arrangeFoldersInHeirarchy();
//    }
  debugPrint("---------END _getYastObjectsFrom");

  debugPrint("---------END _getYastObjectsFrom");
  return mapYastObjects;
} //_getYastObjectsFrom
