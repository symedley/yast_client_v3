import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'Model/record.dart';
import 'Model/yast_db.dart';
import 'utilities.dart';
import 'yast_parse.dart';
import 'package:flutter/foundation.dart';
import 'constants.dart';
import 'utilities.dart' as utilities;

// create copies of records going out into the future.
// plausible fakes.
// These must go into the database and be entered using the yast api
/**
 * Create fake records for TODAY based on a reference day
 * and randomizing the time.
 * Store in database.
 * NOT save to Yast API.
 */
Future<Map<String, Record>> createFutureRecordsFromReferenceRecs(
    Map<String, Record> records,
    int startIdNumber ) async {
  if (records == null ) {
    debugPrint("createFutureRecords called with null collection");
    return null;
  }
  if (records.isEmpty ) {
    debugPrint("createFutureRecords called with empty collection");
    return null;
  }
  DateTime startReferenceDay = DateTime.parse(Constants.referenceDay);
  DateTime endReferenceDay = DateTime(
      startReferenceDay.year,
      startReferenceDay.month,
      startReferenceDay.day,
      23, 59, 0);
  List<Record> recsToCopy = new List();
  DateTime today = DateTime.now();
  records.forEach((String key, Record value) {
    DateTime start = value.startTime;
    // ignore end time for now
    if ((start.compareTo(startReferenceDay) > 0) &&
        (start.compareTo(endReferenceDay) < 0)) {
      recsToCopy.add(value);
    }
  });
  int dayCount = 0;
  Map<String, Record> batchOfNewFakeRecords = new Map();
  Map<String, Record> newFakeRecords = new Map();
  DateTime fakeDay = DateTime.now();//local time zone
  // fakeDay is in local time
  fakeDay = DateTime(fakeDay.year, fakeDay.month, fakeDay.day );
  DateTime fakeTime;
  var rng = new Random(); // used to generate random numbers inside the loop
  int recordCount = 0;
  while (dayCount < Constants.numberOfFakeDaysToMake) {
    //does this modify fakeDAte?
    fakeTime = fakeDay.add(new Duration(hours: Constants.fakeDayMorningStartTime));

    // This is unnecessary because the putRecordsInDatabase method
    // chunks this into blocks of ~ 500 already
//    if (((recordCount % YastDb.FAKERECORDSBATCHLIMIT)==0) && (recordCount != 0)) {
//      await putRecordsInDatabase(batchOfNewFakeRecords);
//      newFakeRecords.addAll(batchOfNewFakeRecords);
//      batchOfNewFakeRecords.clear();
//    }

    recsToCopy.forEach((rec) {
      recordCount++;
      Record fakeRecord = Record.clone(rec);
      fakeRecord.id = startIdNumber.toString();
      startIdNumber++;
      fakeRecord.startTime = fakeTime;
      fakeRecord.startTimeStr = localDateTimeToYastDate(fakeRecord.startTime);
      // records to shorten have project id s 25004182,25004191, 25004239, 25004242
      if ((fakeRecord.projectId.compareTo("25004182") == 0)
            || ( fakeRecord.projectId.compareTo("25004191") == 0)
            || ( fakeRecord.projectId.compareTo("25004239") == 0)
            || ( fakeRecord.projectId.compareTo("25004242") == 0))
      {
        debugPrint(' shortening duration on record {$fakeRecord.id}');
        fakeTime = fakeTime.add (Duration(minutes: 15));
      } else {
        int randomInt = (rng.nextInt(6) - 3) * 5;
        Duration randomDur = Duration(minutes: randomInt);
        fakeTime = fakeTime.add(rec.duration());
        fakeTime = fakeTime.add(randomDur);
      }
      fakeRecord.endTime = fakeTime;
      fakeRecord.endTimeStr = localDateTimeToYastDate(fakeRecord.endTime);
      String fakeKey = fakeRecord.id + (dayCount.toString());
      fakeRecord.id = fakeKey;
      fakeRecord.yastObjectFieldsMap[Record.FIELDSMAPID] = fakeKey;
      fakeRecord.yastObjectFieldsMap[Record.FIELDSMAPTIMEFROM] =
          fakeRecord.startTimeStr;
      fakeRecord.yastObjectFieldsMap[Record.FIELDSMAPTIMETO] =
          fakeRecord.endTimeStr;
      fakeRecord.yastObjectFieldsMap[Record.FIELDSMAPSTARTTIME] =
          fakeRecord.startTimeStr;
      fakeRecord.yastObjectFieldsMap[Record.FIELDSMAPENDTIME] =
          fakeRecord.endTimeStr;
      fakeRecord.yastObjectFieldsMap[Record.FIELDSMAPISRUNNING] = '0';
      fakeRecord.yastObjectFieldsMap[Record.FIELDSMAPCOMMENT] =
          'end time: ${fakeTime.toString()} is example record # $recordCount stored on ${today.toString()}';
      fakeRecord.comment =
          fakeRecord.yastObjectFieldsMap[Record.FIELDSMAPCOMMENT];
      debugPrint('fake rec: id:${fakeRecord.id} comment:${fakeRecord.comment}');
      batchOfNewFakeRecords[fakeKey] = fakeRecord;
    });
    fakeDay = fakeDay.add(new Duration(days: 1));
    dayCount++;
  }
  if (batchOfNewFakeRecords.isNotEmpty) {
    await putRecordsInDatabase(batchOfNewFakeRecords, selectivelyDelete: false);
    newFakeRecords.addAll(batchOfNewFakeRecords);
  }
  return newFakeRecords;
} // create fake records

/// retrieve records from the database ffrom the reference day
/// and use those to clone into fake records
/// Create fake records for purposes of creating a lot of days worth
/// of data for debugging purposes. See Constants for reference and
/// target dates.
///
Future<void> createFakes(theSavedStatus, {int startIdNumber} ) async {
  debugPrint('========== createFakes');

  if ((startIdNumber == null)) {
    try {
      startIdNumber = int.parse(theSavedStatus.currentRecords.keys.last) + 1;
    } catch (e) {
      startIdNumber = 10000000;
    }
  }
  //
  // DEBUG: create future fake records
  DateTime startReferenceDay = DateTime.parse(Constants.referenceDay);
  String startReferenceDayStr =
    utilities.localDateTimeToYastDate(startReferenceDay);
  DateTime endReferenceDay = DateTime(startReferenceDay.year,
      startReferenceDay.month, startReferenceDay.day, 23, 59, 0);
  DateTime today = DateTime.now();
  today = DateTime(today.year,
      today.month, today.day, 0, 0, 0);

  theSavedStatus.counterApiCallsStarted++;

  Map<String, Record> newRecords = new Map();

  // ========================================

  Query query = Firestore.instance.collection(YastDb. DbRecordsTableName)
        .where("startTime", isGreaterThanOrEqualTo: startReferenceDayStr);
  QuerySnapshot qss = await query.getDocuments();
  qss.documents.forEach((recDocSnap) async {
    var recordFromDb = Record.fromDocumentSnapshot(recDocSnap);

    if ((startReferenceDay
        .compareTo((recordFromDb.startTime)) < 0) &&
        (endReferenceDay.compareTo(recordFromDb.startTime)) > 0) {
      newRecords[recordFromDb.id] = recordFromDb;
    }
  } );

  // ========================================
  theSavedStatus.counterApiCallsCompleted++;
  Map<String, Record> newRecs = await createFutureRecordsFromReferenceRecs(newRecords, startIdNumber);

  // create the fake records should also store them in the database.
    theSavedStatus.currentRecords.addAll(newRecs);
} // createFakes

