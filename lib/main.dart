import 'package:flutter/material.dart';
import 'saved_app_status.dart';
import 'home_page_route.dart';
import 'day_summary_panel.dart';
import 'all_projects_panel.dart';
import 'all_folders_panel.dart';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  static const padding = EdgeInsets.all(16.0);

  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Yast Time Management Tool Client',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Yast Client Home Page'),
    );
  }
}

// Home Page of the app is currently some debugging info and a link to a login page.
class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<Tab> myTabs = <Tab>[
    new Tab(text: 'Home'),
    new Tab(text: 'Timeline'),
    new Tab(text: 'All Projects'),
    new Tab(text: 'All Folders'),
   // new Tab(text: 'Database'),
  ];

  static String tag = "my-app";

  static SavedAppStatus _currentAppStatus;

  final routes = <String, WidgetBuilder>{
//    LoginPage.tag: (context) => LoginPage(),

    HomePageRoute.tag: (context) => HomePageRoute(theSavedStatus: _currentAppStatus,),
  };

  @override
  Widget build(BuildContext context) {
    if (_currentAppStatus == null) {
      _currentAppStatus = new SavedAppStatus();
    }

    return new MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Yast Client',
        theme: new ThemeData(
          primarySwatch: Colors.blue,
          primaryColor: Colors.blueGrey,
          accentColor: Colors.blueAccent,
          errorColor: Colors.red[700],
          buttonColor: Colors.lightBlueAccent,
          // TODO fix these ink splash colors
          highlightColor: Theme.of(context).highlightColor,
          splashColor: Theme.of(context).splashColor,
          textTheme: TextTheme(
            body1: TextStyle(
              fontSize: 16.0,
            ),
            caption: TextStyle(
              fontSize: 12.0,
              color: Colors.grey,
            )
      ),
             
          buttonTheme: ButtonThemeData(
            shape: RoundedRectangleBorder(borderRadius:
                BorderRadius.all(
                  Radius.circular(32.0),
                )),
          ),
        ),
        routes: routes,
        home: DefaultTabController(
          length: myTabs.length,
          child: Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(60.0),
              child: AppBar(
                primary: true,
                bottom: TabBar(tabs: myTabs),
            ),
            ),
            body: TabBarView(children: [
              HomePageRoute(
                title: 'Yast Home Page',
                theSavedStatus: _currentAppStatus,
        ),
              DaySummaryPanel(
                // key: key,
                title: "Timeline",
                theSavedStatus: _currentAppStatus,
              ),
              AllProjectsPanel(
                  // key: key,
                  title: "All my projects",
                  theSavedStatus: _currentAppStatus),
              AllFoldersPanel(
                  // key: key,
                  theSavedStatus: _currentAppStatus),
            ]),
          ),
        ));
  }
}
