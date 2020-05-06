import 'package:xml/src/xml/nodes/element.dart';
import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart' as xml;
import 'yast_object.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utilities.dart' as utils;
import '../yast_parse.dart' as YastParse;

class Record extends YastObject {
  //Yast API for Record:
  //  REQUEST
  // "data.getRecords"
  //
  //  The request fields are: (according to the API documentation)
  //
  // id(optional): Comma separated list of requested record identifiers
  //  user(required): Yast user
  //  hash(required): Yast user hash
  //  parentId(optional) : Comma separated list of Ids of the project requested records belong to.
  //  typeId(optional) : Id of the recordType object describing this record
  //  timeFrom(optional) : Time of creation [seconds since 1st of January 1970]
  //  timeTo(optional) : Time of last update [seconds since 1st of January 1970]
  //  userId(optional) : Only relevant for usage through Entity API as Organization. Comma separated list of user identifiers for requested records
  //
  // Response:
  //  <record>
  //    <id>14716517</id>
  //    <typeId>1</typeId>
  //    <timeCreated>1531014659</timeCreated>
  //    <timeUpdated>1531014749</timeUpdated>
  //    <project>3526479</project>
  //    <variables>
  //      <v>1531001100</v>
  //      <v>1531002600</v>
  //      <v><![CDATA[]]></v>
  //      <v>0</v>
  //      <v>0</v>
  //      <v>0</v>
  //    <v>0</v>
  //    </variables>
  //   <creator>3110054</creator>
  //   <flags>0</flags>
  //    <recordRecordTags>
  //    </recordRecordTags>
  //  </record>

  // Types of records: Work record or Phone call
  // Work Record:
  //  A record is a work record if the typeId field is 1.
  // A work record has the following variables in the variables array (in this order):
  //  //  Work Record
  //  A record is a work record if the typeId field is 1. A work record has the following variables in the variables array :
  //
  // 7 variables
  // in the <variables> block: these items are named
  // <v>.
  // they are, in order:
  //
  //  startTime : Start-time of record [seconds since 1st of January 1970]
  //  endTime : End-time of record [seconds since 1st of January 1970]
  //  comment : String with comment for record
  //  isRunning : 1 if the record is running. In that case endTime has not been set yet. Else 0
  //  hourlyCost
  //  hourlyIncome
  //  isBillable

//  static const million = 1000000;
//  static const dateConversionFactor = million;

  static const String FIELDSMAPID = "id";
  static const String FIELDSMAPPROJECTID = "project";
  static const String FIELDSMAPTIMEFROM = 'timeFrom';
  static const String FIELDSMAPTIMETO = 'timeTo';
  static const String FIELDSMAPUSERID = 'userId';
  static const String FIELDSMAPTYPEID = "typeId";

  static const String FIELDSMAPSTARTTIME = 'startTime';
  static const String FIELDSMAPENDTIME = 'endTime';
  static const String FIELDSMAPCOMMENT = 'comment';
  static const String FIELDSMAPISRUNNING = 'isRunning';

  // Phone Call Record Type is ignored because we don't care.

  static const String __object = "record";
  static const String _variables = "variables";
//  static const String _typeId = "typeId";

  //  Record fields. See also those inherited.
  DateTime startTime; // [seconds since 1st of January 1970]
  DateTime endTime;
  String startTimeStr; // [seconds since 1st of January 1970]
  String endTimeStr;
  String comment;
  String isRunning;

//  String flags;
  String projectId;
  String typeId;

  //  Yast gives us these fields, but I don't use them yet.
  //  String hourlyCost;
  //  String hourlyIncome;
  //  String isBillable;

  Record.fromXml(XmlElement xmlElement) : super.fromXml(xmlElement, __object) {
    typeId = yastObjectFieldsMap[FIELDSMAPTYPEID];
    var xmlVariables = xmlElement.findElements(_variables).toList().first;
    List<String> variables = new List();
    try {
      xmlVariables.findElements("v").forEach((it) {
        variables.add(it.text);
      });
      startTimeStr = variables[0];
      endTimeStr = variables[1];
//      startTime = DateTime.fromMillisecondsSinceEpoch(
//          int.parse(startTimeStr) * utils.dateConversionFactor, isUtc:  true);
      startTime = utils.yastTimetoLocalDateTime(startTimeStr);
//      endTime = DateTime.fromMillisecondsSinceEpoch(
//          int.parse(endTimeStr) * utils.dateConversionFactor);
      endTime = utils.yastTimetoLocalDateTime(endTimeStr);
      comment = variables[2];
      isRunning = variables[3];
//       hourlyCost = variables[4];
//       hourlyIncome = variables[5];
//       isBillable = variables[6];
    } catch (e) {
      print(e);
    }
    copyVariablesIntoFieldmap();
    this.projectId = yastObjectFieldsMap[FIELDSMAPPROJECTID];
  }

  // Xml format of type record.
  //     <objects>
  //        <record>
  //            <typeId>1</typeId>
  //            <project>101</project>
  //            <variables>
  //                <v>1279099500</v>
  //                <v>1279105802</v>
  //                <v>Some comment</v>
  //                <v>0</v>
  //            </variables>
  //            <flags>0</flags>
  //        </record>
  //    <objects>
  // TODO shoudl it be XmlDocument or XmlElement?
  xml.XmlNode toXml() {
    var builder = new xml.XmlBuilder();
    builder.processing('xml', 'version="1.0"');
    builder.element(YastParse.recordStr, nest: () {
      builder.element('typeId', nest: () {
        builder.text(this.typeId);
      });
      builder.element('project', nest: () {
        builder.text(this.projectId);
      });
      builder.element('variables', nest: () {
        builder.element('v', nest: () {
          builder.text(this.startTimeStr);
        });
        builder.element('v', nest: () {
          builder.text(this.endTimeStr);
        });
        builder.element('v', nest: () {
          builder.text(this.comment);
        });
        builder.element('v', nest: () {
          builder.text(this.isRunning);
        });
      });
      builder.element('flags', nest: () {
        builder.text(this.flags);
      });
    });
//    var retval = super.toXml() ;
    return builder.build();
  } // toXml

  copyVariablesIntoFieldmap() {
    // Copy the YastObject starttime, endttime, comment and isrunning
    // into the fieldmap with the other variables to make it easier to
    // store in the database.
    Map<String, String> forceType = {
      Record.FIELDSMAPSTARTTIME: this.startTimeStr,
      Record.FIELDSMAPENDTIME: this.endTimeStr,
      Record.FIELDSMAPCOMMENT: this.comment,
      Record.FIELDSMAPISRUNNING: this.isRunning,
    };
    this.yastObjectFieldsMap.addAll(forceType);
  }

// For now, depend on the yastObjectFieldsMap in the superclass to get the
// field values that are specific to work records.
  Record.fromDocumentSnapshot(DocumentSnapshot docSnap)
      : super.fromDocSnap(docSnap, __object) {
    try {
      this.typeId = this.yastObjectFieldsMap[Record.FIELDSMAPTYPEID];
      this.startTimeStr = this.yastObjectFieldsMap[Record.FIELDSMAPSTARTTIME];
      this.endTimeStr = this.yastObjectFieldsMap[Record.FIELDSMAPENDTIME];
      this.comment = this.yastObjectFieldsMap[Record.FIELDSMAPCOMMENT];
      this.isRunning = this.yastObjectFieldsMap[Record.FIELDSMAPISRUNNING];
      startTime = utils.yastTimetoLocalDateTime(startTimeStr);
      endTime = utils.yastTimetoLocalDateTime(endTimeStr);
      this.projectId = this.yastObjectFieldsMap[FIELDSMAPPROJECTID];
    } catch (e) {
      debugPrint(e);
      throw (e);
    }
  }

  Record.clone(Record original) : super.clone(original) {
    try {
      this.typeId = original.typeId;
      this.startTimeStr = original.startTimeStr;
      this.endTimeStr = original.endTimeStr;
      this.comment = original.comment;
      this.isRunning = original.isRunning;
      startTime = original.startTime;
      endTime = original.endTime;
      yastObjectFieldsMap = new Map.from(original.yastObjectFieldsMap);
      this.projectId = original.yastObjectFieldsMap[FIELDSMAPPROJECTID];
    } catch (e) {
      debugPrint(e);
      throw (e);
    }
  }

  String toString() {
    return 'id:$id start:$startTime';
  }

  Duration duration() {
    if ((startTime == null) || (endTime == null)) {
      return null;
    } else {
      return endTime.difference(startTime);
    }
  }
}
