import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'Model/project.dart';
import 'Model/record.dart';
import 'constants.dart';
import 'duration_project.dart';

enum StatusOfApi {
  ApiOk,
  ApiLoginNeeded,
  ApiLoginFailure,
  ApiUnknownFailure,
}

const String logged_in = "Logged in.";
const String api_ok_description = "Response: OK";
const String api_login_needed_description = "Login needed";
const String api_login_failure_description = "Login Failure";
const String api_unknown_failure_description = "Unknown Failure";

// SavedAppStatus class holds onto the top level basic status and info
class SavedAppStatus {
  SavedAppStatus() {
    _getSharedPrefs();
    projects = {};
    _username = "";
    sttOfApi = StatusOfApi.ApiLoginNeeded;
    showValidationError = false;
    counterApiCallsCompleted = 0;
    counterApiCallsStarted = 0;
    currentRecords = {};
    startTimeToRecord = {};
    folderIdToName = {};
    message = '';
  }

  /// used for the developer tools to render a view without real data
  SavedAppStatus.dummy() {
    SavedAppStatus retval = new SavedAppStatus();
    retval.sttOfApi = StatusOfApi.ApiOk;
    retval.setUsername('noname');
    retval.message = 'message in the status';
    retval.hashPasswd = 'bogushashpwd';
  }

  /// Stored Username
  String _username = "";

  String getUsername() => this._username;

  void setUsername(String newUsername) {
    _username = newUsername;
    _savePreferences(newUsername);
  }

  /// Status (logged in, error, whatever)
  /// and the message that goes with it.
  StatusOfApi sttOfApi = StatusOfApi.ApiLoginNeeded;
  bool showValidationError = false;
  int counterApiCallsCompleted = 0;
  int counterApiCallsStarted = 0;
  String message;

  /// Hashed password, as sent back by the yast API when logging in
  String hashPasswd;

  /// Records = timeline records. Map IdString -> Record object
  Map<String, Record> currentRecords = {};

  /// Records indexed by their start time, so you can retrieve them in order
  Map<DateTime, Record> startTimeToRecord = {};

  /// Record Times: look up starttime and endtime by recordId
  DateTime getRecordEndTime(String id) {
    try {
      return currentRecords[id].endTime;
    } on Null {
      return null;
    } on NullThrownError {
      return null;
    }
  }

  DateTime getRecordStartTime(String id) {
    try {
      return currentRecords[id].startTime;
    } on Null {
      return null;
    } on NullThrownError {
      return null;
    }
  }

  /// Records: find record by id and calculate the duration of that timeline record
  Duration durationOfRecord(String id) {
    return this.getRecordEndTime(id).difference(this.getRecordStartTime(id));
  }

  /// Record: duration in # hours and fraction of hours, looked up by id
  /// For purposes of displaying in a human friendly way,
  double howMuchOf24HoursForRecord(String id) {
    return min((durationOfRecord(id).inMinutes + 0.0) / 60.0, 24.0);
  }

  /// Record: duration in # hours and fraction of hours, but cap the max displayed at 6.0
  /// so it fits in the display as a bar graph. 6 hours or more is just "a long time"
  double howMuchOf6HoursForRecord(String id) {
    return min((durationOfRecord(id).inMinutes + 0.0) / 60.0, 6.0);
  }

  /// Map Project ID number (as string) to Project Name.
  /// Look up name or color and don't barf if it's not found.
  Map<String, Project> projects = {};
  Map<String, Duration> projectNameToDuration = {};
  Map<String, Duration> projectIdToDuration = {};
  Map<String, DurationProject> projectIdToDurationProject = {};

  addProject(Project project) {
    projects[project.id] = project;
    projectNameToDuration[project.name] = new Duration();
    projectIdToDuration[project.id] = new Duration();
    projectIdToDurationProject[project.id] =
        new DurationProject(new Duration(), project);
  }

  addAllProjects(Map projMap) {
    projects = projMap;
    resetProjectDurationMap();
    projMap.forEach((name, proj) {
      projectNameToDuration[name] = new Duration();
      projectIdToDuration[proj.id] = new Duration();
      projectIdToDurationProject[proj.id] =
          new DurationProject(new Duration(), proj);
    });
  }

  String getProjectNameFromId(String id) {
    if (projects == null) {
      projects = {};
    }
    try {
      return projects[id].name;
    } on NoSuchMethodError catch (e) {
      debugPrint('$e');
      return "----";
    } on TypeError catch (e) {
      debugPrint('$e');
      return "----";
    } on UnsupportedError catch (e) {
      debugPrint('$e');
      return "----";
    }
  }

  String getProjectColorStringFromId(String id) {
    if (projects == null) {
      projects = {};
    }
    try {
      return projects[id].primaryColor;
    } on NoSuchMethodError catch (e) {
      debugPrint('$e');
      return Constants.COLORSTRING;
    } on TypeError catch (e) {
      debugPrint('$e');
      return Constants.COLORSTRING;
    } on UnsupportedError catch (e) {
      debugPrint('$e');
      return Constants.COLORSTRING;
    }
  }

  Duration getDurationFromProjectId(String id) {
    try {
      return projectIdToDurationProject[id].duration;
    } on NoSuchMethodError catch (e) {
      return null;
    } on TypeError catch (e) {
      return null;
    } on UnsupportedError catch (e) {
      return null;
    }
  }

  /// Create or update the duration values in these maps
  /// in the saved app status:
  ///     projectIdToDuration
  ///     projectNameToDuration
  ///     projectIdToDurationProject
  void addToProjectDuration(
      {@required Project project, Duration duration, int secsFromEpoch}) {
    if ((duration == null)) {
      if ((secsFromEpoch == null) || (secsFromEpoch <= 0)) {
        return; // do nothing
      }
    } else if (duration.inSeconds <= 0) {
      if ((secsFromEpoch == null) || (secsFromEpoch <= 0)) {
        return; // do nothing
      }
    }

    if (project != null) {
      if (project.name != null) {
        if (projectNameToDuration[project.name] != null) {
          projectNameToDuration[project.name] += duration;
          projectIdToDuration[project.id] += duration;
          projectIdToDurationProject[project.id].duration += duration;
        } else {
          // encountered a new project type?
          // should it be added in the project duration map?
          projectNameToDuration[project.name] = duration;
          projectIdToDuration[project.id] = duration;
          projectIdToDurationProject[project.id] =
          new DurationProject(duration, project);
        }
      }
    }
  }

  /// Reset the info about project duration for the currently viewed day
  void resetProjectDurationMap() {
    projectNameToDuration.forEach((k, v) {
      v = new Duration(minutes: 0);
    });
    projectIdToDuration.forEach((k, v) {
      v = new Duration(minutes: 0);
    });
    projectIdToDurationProject.forEach((k, v) {
      v = new DurationProject(Duration(minutes: 0),
          v.project); // TODO check that this isn't messing up the project objects
    });
  }

  List<MapEntry<String, DurationProject>> sortedProjectDurations() {
    projectNameToDuration.entries
        .toList()
        .sort((MapEntry<String, Duration> a, MapEntry<String, Duration> b) {
      return (b.value.inMilliseconds - a.value.inMilliseconds);
    });
    var tmp = projectIdToDurationProject.entries.toList();
    tmp.sort((MapEntry<String, DurationProject> a,
        MapEntry<String, DurationProject> b) {
      return (b.value.duration.inMilliseconds -
          a.value.duration.inMilliseconds);
    });
    return tmp;
  }

  /// Foldernames, by id
  Map<String, String> folderIdToName = {};

  String getFolderNameFromId(String id) {
    if (folderIdToName == null) {
      folderIdToName = {};
    }
    try {
      return folderIdToName[id];
    } on NoSuchMethodError catch (e) {
      print(e);
      return null;
    } on TypeError catch (e) {
      print(e);
      return null;
    } on UnsupportedError catch (e) {
      print(e);
      return null;
    }
  }

  /// Shared preferences to store the last used username for the login screen
  void _getSharedPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    this.setUsername(prefs.getString('username'));
    try {
      String date = (prefs.getString('preferredDate'));
      if (date != null) this.setPreferredDate(DateTime.parse(date));
    } on FormatException catch (e) {
      debugPrint(" Failed to get date from shared preferences. $e");
    }
  }

  void _savePreferences(String newUsername) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', newUsername);
    if (this._preferredDate != null)
      await prefs.setString('preferredDate', this._preferredDate.toString());
  }

  DateTime _preferredDate;

  DateTime getPreferredDate() => _preferredDate;

  setPreferredDate(DateTime newDate) {
    _preferredDate = newDate;
    _savePreferences(this._username);
  }
}
