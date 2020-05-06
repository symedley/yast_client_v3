import 'package:xml/src/xml/nodes/element.dart';
import 'package:xml/xml.dart' as xml;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// One Project object represents one Project from
/// Yast's database.
///
/// Projects are user defined types of work. They can be organized in folders
/// and subfolders. They have user-assigned colors.
abstract class YastObject {
  //
  //  fields from their API documentation:
//  id : Unique id of the project
//  name : Name of the project
//  description : Project description
//  primaryColor : Primary color associated with the project
//  parentId : Id of group if project has parent group or 0 if project is not in a group
//  privileges : Privileges the current user has on this project
//  timeCreated : Time of creation [seconds since 1st of January 1970]
//  creator : Id of the user that created this project
// TODO move these to yast_parse? because that's more intuitive?
  static const String FIELDSMAPID = "id";
  static const String FIELDSMAPNAME = "name";
  // TYPEID ignored for now?
  static const String FIELDSMAPDESCRIPTION = "description";
  static const String FIELDSMAPPRIMARYCOLOR = "primaryColor";
  static const String FIELDSMAPPARENTID = "parentId";
  static const String FIELDSMAPPROJECT = "project";
  static const String FIELDSMAPPRIVILEGES = "privileges";
  static const String FIELDSMAPTIMECREATED = "timeCreated";
  static const String FIELDSMAPCREATOR = "creator";
  static const String FIELDSMAPFLAGS = "flags";

  String id;
  int idNum;
  String name;
  // typeId ignored for now?
  String description;
  String primaryColor;
  String parentId;
  String privileges;
  String timeCreated; // Strings can be replaced with other types later.
  String creator;
  String flags = '0';

  Map<String, String> yastObjectFieldsMap = new Map();

  YastObject();

  YastObject.fromXml(XmlElement xmlElement, String objectType) {
    assert(xmlElement.name.local == objectType);

    xmlElement.children.forEach((it) {
      try {
        try {
          if (it.nodeType == xml.XmlNodeType.ELEMENT) {
            yastObjectFieldsMap.addAll(
                {(it as XmlElement).name.toString(): it.children.first.text});
          }
        } catch (e) {
          debugPrint(e);
        }
        if (it.children.length > 0) {
          this.id = yastObjectFieldsMap[FIELDSMAPID];
          this.name = yastObjectFieldsMap[FIELDSMAPNAME];
          this.description = yastObjectFieldsMap[FIELDSMAPDESCRIPTION];
          this.primaryColor = yastObjectFieldsMap[FIELDSMAPPRIMARYCOLOR];
          this.parentId = yastObjectFieldsMap[FIELDSMAPPARENTID];
          this.privileges = yastObjectFieldsMap[FIELDSMAPPRIVILEGES];
          this.timeCreated = yastObjectFieldsMap[FIELDSMAPTIMECREATED];
          this.creator = yastObjectFieldsMap[FIELDSMAPCREATOR];
        }
      } catch (e) {
        debugPrint(e);
      }
    });
  }

  // Example xml for record type
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
  xml.XmlNode toXml() {
    var builder = new xml.XmlBuilder();
    var returnXml = builder.build();

    builder.processing('xml', 'version="1.0"');
    builder.element('typeId', nest: () {
      builder.text('1');
    });
    builder.element('project', nest: () {
      builder.text("bogus");
    });
    builder.element('typeId', nest: () {
      builder.text("bogus");
    });

//    yastObjectFieldsMap[ID] = this.id;
//    yastObjectFieldsMap[NAME] = this.name;
//    ? typeID?
//    yastObjectFieldsMap[DESCRIPTION] = this.description;
//    yastObjectFieldsMap[PRIMARYCOLOR] = this.primaryColor;
//    yastObjectFieldsMap[PARENTID] = this.parentId;
//    yastObjectFieldsMap[PRIVILEGES] = this.privileges;
//    yastObjectFieldsMap[TIMECREATED] = this.timeCreated;
//    yastObjectFieldsMap[CREATOR] = this.creator;
//
    return returnXml;
  }

  YastObject.fromDocSnap(DocumentSnapshot docSnap, String objectType) {
    try {
      docSnap.data.forEach((String key, dynamic value) {
        try {
          yastObjectFieldsMap[key] = value;
        } catch (e) {
          debugPrint(e);
          throw (e);
        }
      });
      if (docSnap.data.length > 0) {
        this.id = yastObjectFieldsMap[FIELDSMAPID];
        this.name = yastObjectFieldsMap[FIELDSMAPNAME]; // name doesn't exist for all object types
        this.description = yastObjectFieldsMap[FIELDSMAPDESCRIPTION];
        this.primaryColor = yastObjectFieldsMap[FIELDSMAPPRIMARYCOLOR];
        this.parentId = yastObjectFieldsMap[FIELDSMAPPARENTID];
        this.privileges = yastObjectFieldsMap[FIELDSMAPPRIVILEGES];
        this.timeCreated = yastObjectFieldsMap[FIELDSMAPTIMECREATED];
        this.creator = yastObjectFieldsMap[FIELDSMAPCREATOR];
      }
    } catch (e) {
      debugPrint(e);
      throw (e);
    }
  }

  getIdNum() {
    if (idNum == null) {
      try {
        idNum = int.parse(id);
      } catch(e) {
        return 0;
      }
    }
    return idNum;
  }

  YastObject.clone(YastObject original) {
    original.yastObjectFieldsMap.forEach((String key, String value) {
      yastObjectFieldsMap[key] = value;
    });
    this.id = original.id;
    this.name = original.name;
    this.description = original.description;
    this.primaryColor = original.primaryColor;
    this.parentId = original.parentId;
    this.privileges = original.privileges;
    this.timeCreated = original.timeCreated;
    this.creator = original.creator;
  }

  String toString() {
    return this.name + ":   " + this.description;
  }
}
