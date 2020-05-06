import 'package:xml/xml.dart' as xml;

class YastResponse{

  static const String yastSuccess = "0";
  static const String yastUnknownError ="1" ;
  static const String yastAccessDenied = "3" ;
  static const String yastNotLoggedIn = "4" ;
  static const String yastLoginfailure = "5" ;
  static const String yastInvalidInput = "6" ;
  static const String yastSubscriptionRequired = "7" ;
  static const String yastDataFormatError = "8" ;
  static const String yastNoRequest =		"9" ;
  static const String yastInvalidRequest = "10" ;
  static const String yastMissingFields = "11" ;
  static const String yastRequestTooLarge = "12" ;
  static const String yastServerMaintenance = "13" ;

  static const Map responseCodes = {
    yastSuccess : "Success",
    yastUnknownError: "Unknown error",
    yastAccessDenied : "Access denied",
    yastNotLoggedIn: "Not logged in",
    yastLoginfailure: "Login failure",
    yastInvalidInput : "Invalid input",
    yastSubscriptionRequired: "Subscription required",
    yastDataFormatError: "Data format error",
    yastNoRequest: "No request",		// (remember to set the Content-Type header)
    yastInvalidRequest : "Invalid request",
    yastMissingFields : "Missing fields",
    yastRequestTooLarge: "Request too large",
    yastServerMaintenance : "Server maintenance"
  };


  String status;
  String id;
  String statusString;
  xml.XmlDocument body;

  YastResponse(xml.XmlDocument xmlDoc) {
    var listOfOne = xmlDoc.findElements("response");
    xml.XmlElement response  = listOfOne.first;
    status = response.getAttribute("status");
    id = response.getAttribute("id");
    statusString = responseCodes[status];

    body = xmlDoc;
  }
}
