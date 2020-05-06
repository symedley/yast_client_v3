///
/// TabState - an abstract superclass to build my Stateful Widget
/// State classes from. Adds a red appbar that alerts user that
/// not logged in.
///
/// sub classes must do this:
///  @override
///  Widget build(BuildContext context) {
///    return super.build(
///    ...and then fill in all the visible stuff for that tab
///
/// or require a method buildInnerStuff , which this build method then calls.

import 'package:flutter/material.dart';
import 'dart:core';
import 'saved_app_status.dart';

Widget displayLoginStatus(
    {SavedAppStatus savedAppStatus, BuildContext context, Widget child}) {
  if (savedAppStatus.sttOfApi != StatusOfApi.ApiOk) {
    return new Scaffold(
        appBar: AppBar(
            backgroundColor: Theme.of(context).errorColor,
            centerTitle: true,
            title: new Text('Not logged in')),
        body: Container(
          constraints: BoxConstraints.expand(),
          child: child,
        ));
  } else {
    return child;
  }
}
