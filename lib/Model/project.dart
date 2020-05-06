import 'package:xml/xml.dart';
import 'package:xml/src/xml/nodes/element.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'yast_object.dart';

/// One Project object represents one Project from
/// Yast's database.
///
/// Projects are user defined types of work. They can be organized in folders
/// and subfolders. They have user-assigned colors.
class Project extends YastObject {
  //
  //  fields from yast API documentation
  // are inherited from abstract superclass
  //  id : Unique id of the project
  //  name : Name of the project
  //  description : Project description
  //  primaryColor : Primary color associated with the project
  //  parentId : Id of group if project has parent group or 0 if project is not in a group
  //  privileges : Privileges the current user has on this project
  //  timeCreated : Time of creation [seconds since 1st of January 1970]
  //  creator : Id of the user that created this project

  static const String __object = "project";

  Project.fromXml(XmlElement xmlElement) : super.fromXml(xmlElement, __object);
  Project.fromDocumentSnapshot(DocumentSnapshot docSnap) : super.fromDocSnap(docSnap, __object);
}
