import 'yast_response.dart';
import 'package:xml/xml.dart' as xml;
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'constants.dart';

const String _scheme = "www.yast.com";
const String _pathForApi = "/1.0/";
const String _httpHeaderContentType = "Content-type";
const String _httpHeadValueContentType =
    "application/x-www-form-urlencoded";

const String _httpHeaderAccept = "Accept";
const String _httpHeadValueAccept = "text/xml";

const String _request = "request="; // must precede the XML
//

/// sendToYastApi - clean up the payload, create URI and add
/// bits and pieces that make it work.
Future<YastResponse> sendToYastApi(String payload) async {
  var uri = new Uri.http(
    _scheme,
    _pathForApi,
  );
  payload = _stripOutWhiteSpace(payload);
  // payload = '<request req="auth.login" id="${sendCounter.toString()}">' + payload + '</request>';
  xml.XmlDocument xmlDoc;
  try {
    xmlDoc = await _httpPostToYast(uri, _request + payload);
  } catch (e) {
    debugPrint("Exception sending or awaiting HTTP post $e");
    debugPrint("payload was $payload");
    return null;
  }
  YastResponse yastResponse = YastResponse(xmlDoc);
  return yastResponse;
}

/// httpPostToYast - add HTTP headers and send the POST message off to the server
Future<xml.XmlDocument> _httpPostToYast(Uri uri, dynamic httpPostBody) async {
  Map<String, String> headers = {
    _httpHeaderContentType: _httpHeadValueContentType,
    _httpHeaderAccept: _httpHeadValueAccept
  };

  try {
    final response = await http
        .post(uri, headers: headers, body: httpPostBody)
        .timeout(Duration(seconds: Constants.HTTP_TIMEOUT));

    if (response.statusCode == 200) {
      // If server returns an OK response, parse the JSON
      xml.XmlDocument doc = (xml.parse(response.body));
      return doc;
    } else {
      // If that response was not OK, throw an error.
      debugPrint(
          'HTTP response status code was not 200: it was : $response.statusCode');
      throw Exception('Failed to get HTTP POST response');
    }
  } on TimeoutException catch (e) {
    debugPrint('HTTP response timed out');
    throw e;
    // A timeout occurred.
  }
} // httpPostToYast

String _stripOutWhiteSpace(String input) {
  String retval = input.replaceAll(new RegExp(r">[\s|\r|\n|\t]*"), ">");
  input = retval.replaceAll(new RegExp(r"[\s|\r|\n|\t]*<"), "<");
  return input;
}
