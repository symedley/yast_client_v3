import 'dart:math';
import 'Model/record.dart';
import 'utilities.dart';
import 'yast_parse.dart';
import 'Model/yast_db.dart';
import 'package:flutter/foundation.dart';
import 'constants.dart';

// create copies of records going out into the future.
// plausible fakes.
// These must go into the database and be entered using the yast api
Future<Map<String, Record>> createFutureRecords(
    Map<String, Record> records) async {
  if (records == null ) {
    debugPrint("createFutureRecords called with null collection");
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
  DateTime fakeDay = DateTime.parse(Constants.firstFakeRecordsDay);//local time zone
  // fakeDay is in local time
  fakeDay = DateTime(fakeDay.year, fakeDay.month, fakeDay.day );
  DateTime fakeTime;
  var rng = new Random();
  int recordCount = 0;
  while (dayCount < Constants.numberOfFakeDaysToMake) {
    //does this modify fakeDAte?
    fakeTime = fakeDay.add(new Duration(hours: Constants.fakeDayMorningStartTime));

    // This is unnecessary because the putRecordsInDatabase method
    // chunks this into blocks of ~ 500 for you.
//    if (((recordCount % YastDb.FAKERECORDSBATCHLIMIT)==0) && (recordCount != 0)) {
//      await putRecordsInDatabase(batchOfNewFakeRecords);
//      newFakeRecords.addAll(batchOfNewFakeRecords);
//      batchOfNewFakeRecords.clear();
//    }
    recsToCopy.forEach((rec) {
      recordCount++;
      Record fakeRecord = Record.clone(rec);
      fakeRecord.startTime = fakeTime;
      fakeRecord.startTimeStr = localDateTimeToYastDate(fakeRecord.startTime);
      int randomInt = (rng.nextInt(6) -3 ) * 5;
      Duration randomDur = Duration(minutes: randomInt);
      fakeTime = fakeTime.add(rec.duration());
      fakeTime = fakeTime.add(randomDur);
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
          'end time:${fakeTime.toString()} is # $recordCount stored on ${today.toString()}';
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
