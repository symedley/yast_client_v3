import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:charts_common/common.dart' as common;
import 'package:intl/intl.dart';

import 'saved_app_status.dart';
import 'display_login_status.dart';
import 'Model/yast_db.dart';
import 'Model/project.dart';
import 'Model/record.dart';
import 'utilities.dart' as utilities;
import 'yast_api.dart' ;
import 'constants.dart';
import 'duration_project.dart';
import 'debug_create_future_records.dart' as debug_create;

const double barTextEdgeInsets = 12.0;
const double barEdgeInsets = 2.0;
const double barWidth = 200.0;
const double loginStatusWidth = 400.0;
const double pieChartWidth = 300.0;
const double barHeight = 30.0;
//const Color dateChooserButtonColor = Color(0xff9e9e9e); //Colors.grey[300];??
//const Color dummy  = Colors.grey[400];
const String rankKeyStr = "pie";
const String segmentKeyStr = "segment";
const String entriesKeyStr = "entries";
const String stackKeyStr = "stack";

class DaySummaryPanel extends StatefulWidget {
  DaySummaryPanel({Key key, this.title, this.theSavedStatus}) : super(key: key);

  final String title;

  static const Color backgroundColor =
      const Color(0xFFF9FBE7); // why can't i say Colors.lime[50]?

  @override
  _DaySummaryPanelState createState() =>
      new _DaySummaryPanelState(this.theSavedStatus);

  final SavedAppStatus theSavedStatus;
}

class _DaySummaryPanelState extends State {
  YastApi api;

  _DaySummaryPanelState(this.theSavedStatus) {
    api = YastApi.getApi();
    _fromDate = theSavedStatus.getPreferredDate();
    if (_fromDate == null) {
      _fromDate = new DateTime.now();
      _fromDate = new DateTime(_fromDate.year, _fromDate.month, _fromDate.day);
      theSavedStatus.setPreferredDate(_fromDate);
    }
    _beginDaySeconds = utilities.localDateTimeToYastDate(_fromDate);
    DateTime tmpDate = _fromDate.add(Duration(hours: 24));
    _endDaySeconds = utilities.localDateTimeToYastDate(tmpDate);
  }

  final SavedAppStatus theSavedStatus;

//  charts.PieChart pieChart;
  Widget pieChart;

  /// Upate the top level map of project ID string to Project object
  /// (the in-memory cache, essentially)
  void updateProjectIdToName() async {
    var idToProject = await Firestore.instance
        .collection(YastDb.DbProjectsTableName)
        .getDocuments();
    idToProject.documents.forEach((DocumentSnapshot ds) {
      var project = Project.fromDocumentSnapshot(ds);
      theSavedStatus.addProject(project);
    });
  }

  void _onTap() async {}

  /// call _pickDate when the user clicks on the date
  /// at the top of the window.
  void _pickDate() async {
    if (false == utilities.basicCheck(theSavedStatus.getUsername(), theSavedStatus.hashPasswd)) {
      utilities.showSnackbar(_scaffoldContext, "Did you mean to log in first?");
    }
    var tmpDate = await showDatePicker(
        context: _scaffoldContext,
        initialDate: _fromDate,
        firstDate: new DateTime(2018, 1, 1),
        lastDate: new DateTime.now());
    _fromDate = (tmpDate == null) ? _fromDate : tmpDate;
    theSavedStatus.setPreferredDate(_fromDate);
    _beginDaySeconds = utilities.localDateTimeToYastDate(_fromDate);
    DateTime tmp = _fromDate.add(Duration(hours: 24));
    _endDaySeconds = utilities.localDateTimeToYastDate(tmp);
    setState(() {
      // even if user is not logged in, this will cause the StreamBuilder
      // to be rebuilt with a query for the new date, and that will
      // pull any records from the database.
     });
  }

  BuildContext _scaffoldContext;
  DateTime _fromDate;
  String _beginDaySeconds, _endDaySeconds;

  @override
  Widget build(BuildContext context)  {
    // start a retrieve which will automatically get records around the current preferred day
    // This is an async, and it's ok for it to complete later because the Stream in the build()
    // function is listening to the same FireStore data that this retrieve call is affecting.
    api.yastRetrieveRecords(theSavedStatus, selectivelyDelete:false);
    theSavedStatus.resetProjectDurationMap();
    updateProjectIdToName();
    _scaffoldContext = context;
    List<charts.Series> data;

    return displayLoginStatus(
      savedAppStatus: theSavedStatus,
      context: context,
      child: Container(
        constraints: BoxConstraints.expand(width: loginStatusWidth),
        color: DaySummaryPanel.backgroundColor,
        padding:
            const EdgeInsets.only(left: 8.0, top: 8.0, right: 8.0, bottom: 8.0),
        child: new Scaffold(
          resizeToAvoidBottomPadding: true,
          backgroundColor: DaySummaryPanel.backgroundColor,
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child:  new StreamBuilder(
                stream: Firestore.instance
                    .collection(YastDb.DbRecordsTableName)
                    .where("startTime",
                        isGreaterThanOrEqualTo: _beginDaySeconds)
//        Are compound queries not supported in Dart/Flutter?fab
//                .where("endTime",
//                        isLessThanOrEqualTo: _endDaySeconds")
                    .snapshots(),
                builder: (context, snapshot) {
                  // Loading...
                  debugPrint('starttime {$_beginDaySeconds}');
                  if ((!snapshot.hasData) || ((theSavedStatus.projects?.isEmpty)??false)) {
                    return const Text('Loading...');
                  }

                  // FIXING the mess
                  // copy the projects map into a map to DurationProjects.
                  // everytime you encoutner a DB record, look up
                  // in the map of DurationProjects and add the duration
                  // to that entry.
                  // Sort the map
                  // Create pie chart data segments from the map entries
                  // with > 0 duration.
                  // BUT WAIT: don't keep recreating those maps
                  // inside the stream builder.
                  // How about a simple Map projectname->duration?
                  List<DocumentSnapshot> dss = snapshot.data.documents;

                  // Records, Filter records and Pie chart

                  dss.forEach((DocumentSnapshot ds) {
                    // putting in app's model.
                    var recordFromDb = Record.fromDocumentSnapshot(ds);
                    theSavedStatus.currentRecords[recordFromDb.id] =
                        recordFromDb;
                    theSavedStatus.startTimeToRecord[recordFromDb.startTime] =
                        recordFromDb;
                    debugPrint(
                        'in Streambuilder, retrieved rec: ${recordFromDb.id} ${recordFromDb.comment}');

                    if ((_beginDaySeconds
                                .compareTo((recordFromDb.startTimeStr)) <
                            0) &&
                        (_endDaySeconds.compareTo(recordFromDb.startTimeStr)) >
                            0) {
                      theSavedStatus.addToProjectDuration(
                          project:
                              theSavedStatus.projects[recordFromDb.projectId],
                          duration: recordFromDb.duration());
                    } else {
                      debugPrint(
                          'Record ${recordFromDb.toString()} was NOT in range to be displayed. why?');
                    }
                  });
                  if (theSavedStatus.currentRecords.isEmpty) { // NEW fakes
                    debug_create.createFakes(theSavedStatus,
                        int.parse( theSavedStatus.currentRecords.keys.last) + 1 );
                  }

                  //Sort the duration projects
                  List<MapEntry<String, DurationProject>> sorted =
                      theSavedStatus.sortedProjectDurations();

                  data = createPieSegmentsChartsFlutter(sorted, theSavedStatus);
//                  if (pieChart == null) {
                  if (data != null) {
                    pieChart = createPieChartsFlutter(data);
                  } else {
                    // draw a circle instead f a pie chart
                    pieChart = new Container(
                      width: Constants.EMPTYPIECIRCLEWIDTH,
                      height: Constants.EMPTYPIECIRCLEWIDTH,
                      decoration: new BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment(0.0, 0.0),
                      child: Text(
                        Constants.emptyPieChartMessage,
                        style: Theme.of(context).textTheme.caption,
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        //
                        // Date chooser button:
                        Container(
                          padding: EdgeInsets.only(top: 10.0),
                          alignment: Alignment(0.0, -1.0),
                          width: pieChartWidth,
                          height: barHeight,
                          child: FlatButton(
                            onPressed: _pickDate,
                            color: Constants.dateChooserButtonColor,
                            child: Text(
                              DateFormat.MMMMd().format(_fromDate),
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ),
                        //
                        // Pie chart
                        Container(
                          height: Constants.PIECONTAINERWIDTH,
                          width: Constants.PIECONTAINERWIDTH,
                          child: Center(
                            child: pieChart,
                          ),
                        ),

                        //
                        // Column of project rectangle bars
                        Expanded(
                          child: new ListView.builder(
                            itemCount: sorted.length,
                            //orderedProjectsList.length,
                            shrinkWrap: true,
                            itemExtent: 35.0,
                            itemBuilder: ((context, index) {
                              //
                              // one Project rectangle bar
                              // this looks really inefficient
                              return projectBar(sorted[index]);
                            }),
                          ),
                        )
                      ]);
                }),
          ),
        ),
      ),
    );
  }

// only the hours and minutes part
  String formatDuration(Duration duration) {
    final formatter = new NumberFormat("##");
    final formatter2 = new NumberFormat("00");
    int hours = duration.inHours % Duration.hoursPerDay;
    int minutes = duration.inMinutes % Duration.minutesPerHour;
    return formatter.format(hours) + ":" + formatter2.format(minutes);
  }

  /// Create pie using flutter_charts

  charts.PieChart createPieChartsFlutter(List<charts.Series> data) {
    var pieChart = new charts.PieChart(data,
        animate: true,
        // Add an [ArcLabelDecorator] configured to render labels outside of the
        // arc with a leader line.
        //
        // Text style for inside / outside can be controlled independently by
        // setting [insideLabelStyleSpec] and [outsideLabelStyleSpec].
        //
        // Example configuring different styles for inside/outside:
        //       new charts.ArcLabelDecorator(
        //          insideLabelStyleSpec: new charts.TextStyleSpec(...),
        //          outsideLabelStyleSpec: new charts.TextStyleSpec(...)),
        defaultRenderer: new charts.ArcRendererConfig(
//                arcRatio: 0.999,
            arcWidth: 150,
            arcRendererDecorators: [
              new charts.ArcLabelDecorator(
                  insideLabelStyleSpec: new charts.TextStyleSpec(
                      color: common.Color.black, fontSize: 12),
                  outsideLabelStyleSpec: new charts.TextStyleSpec(
                      color: common.Color.black, fontSize: 12))
            ]));
    return pieChart;
  }

  /// Create pie segments from the DurationProject data, which should be sorted
  /// use flutter_charts
  List<charts.Series> createPieSegmentsChartsFlutter(
      List<MapEntry<String, DurationProject>> projIdToDurProj, theSavedStatus) {
    // First, change the usedProjectsList into simpler data
    List<PieChartData> data = new List();
    projIdToDurProj.forEach((kv) {
      if (kv.value.duration.inMinutes > 0) {
        data.add(new PieChartData(
            kv.value.duration.inMinutes - 0.00001,
            kv.value.project.name,
            theSavedStatus.getProjectColorStringFromId(kv.key)));
      }
    });
    var retval;
    if (data.isEmpty) {
      retval = null;
    } else {
      retval = [
        new charts.Series<PieChartData, int>(
          id: 'Where time went',
          domainFn: (PieChartData pcd, _) => (pcd.getDuration().round()),
          measureFn: (PieChartData pcd, _) => (pcd.getDuration().round()),
          // dp.getDurationNumber()
          data: data,
          // Set a label accessor to control the text of the arc label.
          labelAccessorFn: (PieChartData row, _) => '${row.getProjectName()}',

          outsideLabelStyleAccessorFn: _outsideLabelStyleAccessorFn,
          insideLabelStyleAccessorFn: _insideLabelStyleAccessorFn,
          fillColorFn: (_, __) => common.Color.fromHex(code: '#00FF00'),
          // common.Color.black ,
          colorFn: (pieChartData, index) => common.Color.fromHex(
              code: pieChartData
                  .colorStr), // common.Color.fromHex(code: '#00FF00'),     // ('#00FF00'),
        )
      ];
    }
    return retval;
  }

  common.TextStyleSpec _outsideLabelStyleAccessorFn(PieChartData pcd, int i) {
    return common.TextStyleSpec(
        fontFamily: 'Arial', fontSize: 12, color: common.Color.black);
  }

  common.TextStyleSpec _insideLabelStyleAccessorFn(PieChartData pcd, int i) {
    return common.TextStyleSpec(
        fontFamily: 'Arial', fontSize: 12, color: common.Color.white);
  }

  Text textForOneProjectColorBar(Duration dura) {
    return Text(((dura != null) && (dura.inMinutes != 0))
        ? " ${formatDuration(dura)}"
        : "");
  }

  Container projectBar(MapEntry<String, DurationProject> projectIdToProjDur) {
    //}  DurationProject theProjectWithDuration) {
    return Container(
      constraints: BoxConstraints.expand(width: loginStatusWidth),
      padding: new EdgeInsets.all(barEdgeInsets),
      child: InkWell(
        borderRadius: BorderRadius.circular((Constants.BORDERRADIUS) / 4),
        highlightColor: Theme.of(context).highlightColor,
        splashColor: Theme.of(context).highlightColor,
        onTap: _onTap,
        child: Row(children: [
          Container(
            width: barWidth,
            child: Container(
                margin: new EdgeInsets.all(2.0),
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.all(Radius.circular(Constants.BORDERRADIUS)),
                  color: utilities.hexToColor(
                      theSavedStatus
                          .getProjectColorStringFromId(projectIdToProjDur.key),
                      transparency: 0xff0000000),
                ),
                alignment: Alignment(1.0, 0.0),
                //
                // Time text
                child: Padding(
                  padding: EdgeInsets.only(
                      left: barTextEdgeInsets, right: barTextEdgeInsets),
                  child: textForOneProjectColorBar(
                      projectIdToProjDur.value.duration),
                )),
          ),
          Flexible(
              child: Text(
            " ${projectIdToProjDur.value.project.name}",
//                overflow: TextOverflow.ellipsis,
            overflow: TextOverflow.fade,
          ))
        ]),
      ),
    );
  } // projectBar
}

class PieChartData {
  PieChartData(this.duration, this.projectName, this.colorStr);

  double duration;

  double getDuration() {
    return duration;
  }

  String projectName;

  String getProjectName() {
    return projectName;
  }

  String colorStr;

  String getColorStr() => colorStr;
}
