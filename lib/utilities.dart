import 'package:flutter/material.dart';


// Constants
//
// for DateTime conversion, since yast uses seconds from epoch
// but Dart DateTime uses millisecondsSinceEpoch and microsecondsSinceEpoch
//
const int million = 1000000;
const int thousand = 1000;
const int dateConversionFactor = thousand;


/// Convert a yast time string to a DateTime object in local time
///
/// Yast time strings are seconds since epoch in UTC.
DateTime yastTimetoLocalDateTime(String dateTimeString) {
  DateTime retval;
  try {
    int millisecondsSinceEpoch = int.parse(dateTimeString) *
        dateConversionFactor;
    DateTime utc = new DateTime.fromMillisecondsSinceEpoch(
        millisecondsSinceEpoch, isUtc: true);
    retval = utc.toLocal();
  } catch (e) {
    debugPrint(e);
    debugPrint("------failure converting date-------");
    return null;
  }
  return retval;
}

/// convert a DateTime object in local time into a yast time string
/// which is seconds since epoch in _UTC_
String localDateTimeToYastDate(DateTime inputDate) {
  String retval;
  if (inputDate == null ) {
    return null;
  }
  try{
    DateTime utc = inputDate.toUtc();
    int tmp = (inputDate.millisecondsSinceEpoch  / dateConversionFactor).round();
    tmp = (utc.millisecondsSinceEpoch  / dateConversionFactor).round();
    int it = tmp as int;
    retval = it.toString();
  }
  catch(e) {
    debugPrint(e);
    debugPrint("------failure converting date to string-------");
    return null;
  }
  return retval;
}

  int dateTimetoSecondsSinceEpoch(DateTime date) {
     return date.millisecondsSinceEpoch ~/ dateConversionFactor;
  }


/// Construct a color from a hex code string, of the format #RRGGBB.
///  optional transparency, defaults to 0x88000000
Color hexToColor(String code, {int transparency = 0xff0000000}) {
  Color retval;
//  debugPrint("hexToColor: $code transparency: $transparency ............");
  try {
    retval =  new Color(int.parse(code.substring(1, 7), radix: 16) |
    (transparency));
  } catch (e) {
    retval =  Color(0xffffffffff);
  }
//  debugPrint("hexToColor: $retval ............");
  return retval;
}

void showSnackbar(BuildContext scaffoldContext, String theMesg) {
  final snackBar = SnackBar(
    content: Text(theMesg),
    action: SnackBarAction(
      label: 'OK',
      onPressed: () {
        // Some code to undo the change!
      },
    ),
  );
  Scaffold.of(scaffoldContext).showSnackBar(snackBar);
}

bool basicCheck(String username, String hashPwd) {
  if ((username == null) || (username.runtimeType != String)) {
    debugPrint("Attempt to retrieve something when there is no username!");
    debugPrint("username = $username");
    return false;
  }
  if ((hashPwd == null) || (hashPwd.runtimeType != String)) {
    debugPrint(
        "Attempt to retrieve something when there is no hash password!");
    debugPrint("hashPwd = $hashPwd");
    return false;
  }
  return true;
}
