
/// Just organizing hte database stuff
class YastDb {
  static const DbProjectsTableName = "projects_";
  static const DbFoldersTableName = "folders_";
  static const DbRecordsTableName = "records_";
  static const DbIdToProjectTableName = 'idToProjectMap_';


  static const int BATCHLIMIT = 500;
  static const int FAKERECORDSBATCHLIMIT = BATCHLIMIT  ~/ 15; // estimate no more than 15 records per day. This is the number of times that one day will be copied, not the total # of records

  // for debugging, reduce the number of records to something
  // that i can examine under a debugger. Usually, I get 600+ records.
  static const LIMITCOUNTOFRECORDS = null;

}
