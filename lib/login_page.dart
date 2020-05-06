import 'dart:core';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'saved_app_status.dart';
import 'yast_api.dart';
import 'constants.dart';

class LoginPage extends StatefulWidget {
  LoginPage({Key key, @required this.theSavedState});

  static String tag = 'login-page';
  final SavedAppStatus
      theSavedState; // this is a reference back to the main level saved state.

  @override
  _LoginPageState createState() =>
      new _LoginPageState(this.theSavedState.getUsername());
}

class _LoginPageState extends State<LoginPage> {
  _LoginPageState(this.username) {
    usernameTextController = TextEditingController();
    usernameTextController.text = username;
  }

  String username; // saves the latest username to shared preferences.
  final passwdTextController = TextEditingController();
  TextEditingController usernameTextController;

  bool _loginInProgress;

  @override
  void dispose() {
    passwdTextController.dispose();
    super.dispose();
  }

  BuildContext _scaffoldContext;

  @override
  Widget build(BuildContext context) {
    _scaffoldContext = context;
    _loginInProgress = false;
    final email = TextFormField(
      controller: usernameTextController,
      keyboardType: TextInputType.emailAddress,
      autofocus: false,
      initialValue: null,
      decoration: InputDecoration(
        hintText: 'Email',
        contentPadding: EdgeInsets.all(Constants.EDGEINSETS),
        // fromLTRB(20.0, 10.0, 20.0, 10.0),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Constants.BORDERRADIUS)),
      ),
    );

    void _onTap() async {
      var usernameTextInput = Text(usernameTextController.text);
      try {
        username = usernameTextInput.data;
      } catch (e) {
        username = '';
      }
      widget.theSavedState.setUsername(username);
      if (_loginInProgress != true) {
        try {
          var passwdTextInput = Text(passwdTextController.text);
          var pw = passwdTextInput.data;
          final snackBar = SnackBar(
            content: Text('Please wait...'),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {
                // Some code to undo the change!
              },
            ),
          );
          Scaffold.of(_scaffoldContext).showSnackBar(snackBar);

          _loginInProgress = true;
          String retval = await attemptLogin(pw);

          if (retval != null) {
            _loginInProgress = false;
            Navigator.pop(context, retval);
          } else {
            // retval is null, so the HTTP login request failed for unknown reason
            _loginInProgress = false;

            final snackBar = SnackBar(
              content: Text('Login failed'),
              duration: Duration(seconds: 10),
              action: SnackBarAction(
                label: 'OK',
                onPressed: () {},
              ),
            );
            Scaffold.of(_scaffoldContext).showSnackBar(snackBar);
          }
        } on TimeoutException catch (e) {
          debugPrint("Login timed out: $e");
          showSnackbar(_scaffoldContext, 'Login timed out.');
          _loginInProgress = false;
        }
      } else {
        debugPrint('Login already in progress when login button clicked');
        showSnackbar(_scaffoldContext, 'Login already in progress.');
      }
      //Navigator.of(context).pop(retval);
    } // _onTap method for InkWell

    final password = TextFormField(
      controller: passwdTextController,
      keyboardType: TextInputType.text,
      autofocus: true,
      initialValue: null,
      obscureText: true,
      decoration: InputDecoration(
        hintText: 'Password',
        contentPadding: EdgeInsets.all(Constants.EDGEINSETS),
        // fromLTRB(20.0, 10.0, 20.0, 10.0),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Constants.BORDERRADIUS)),
      ),
    );

    final loginButton = Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.lightBlueAccent,
          borderRadius:
              BorderRadius.all(Radius.circular(Constants.BORDERRADIUS)),
        ),
        padding: const EdgeInsets.all(Constants.EDGEINSETS),
        child: InkWell(
          borderRadius: BorderRadius.circular(Constants.BORDERRADIUS),
          highlightColor: Colors.yellow,
          splashColor: Colors.white,
          onTap: _onTap,
          child: Center(
            child: Text(
              'Log In',
              style: TextStyle(
                  fontSize: Theme.of(context).textTheme.body1.fontSize,
                  color: Colors.white),
            ),
          ),
        ),
      ),
    );

    final forgotLabel = FlatButton(
      child: Text(
        'Forgot password?',
        style: TextStyle(color: Colors.black54),
      ),
      onPressed: () {},
    );

    final cancelButton = FlatButton(
      child: Text(
        'Cancel',
        style: TextStyle(color: Colors.black54),
      ),
      onPressed: () {
        _loginInProgress = false;
        Navigator.pop(context, null);
      },
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: new Builder(builder: (BuildContext context) {
        _scaffoldContext = context;
        return Padding(
          padding: const EdgeInsets.only(
              left: 8.0, top: 80.0, right: 8.0, bottom: 20.0),
          child: Container(
            alignment: Alignment.topCenter,
            child: ListView(
              shrinkWrap: true,
              children: <Widget>[
                SizedBox(height: 48.0),
                email,
                SizedBox(height: 8.0),
                password,
                SizedBox(height: 24.0),
                loginButton,
                forgotLabel,
                cancelButton,
              ],
            ),
          ),
        );
      }),
    );
  }

  /// NOw try to log in with the password the user just entered.
  Future<String> attemptLogin(String inputPasswd) async {
    YastApi api = YastApi.getApi();

    String retval = await api.yastLogin(username, inputPasswd);
    if (retval != null) {
      return retval;
    } else {
      debugPrint("Failed: in attemptLogin, retval = $retval");
      return null;
    }
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
}
