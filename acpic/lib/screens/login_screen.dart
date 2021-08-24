// IMPORT FLUTTER PACKAGES
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;
// IMPORT UI ELEMENTS
import 'package:acpic/ui_elements/cupertino_elements.dart';
import 'package:acpic/ui_elements/android_elements.dart';
import 'package:acpic/ui_elements/material_elements.dart';
import 'package:acpic/ui_elements/constants.dart';

//IMPORT SCREENS
import 'start.dart';

class LoginScreen extends StatefulWidget {
  static const String id = 'login_screen';
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    return GestureDetector(
      // This makes the keyboard disappear when tapping outside of it
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: SafeArea(
              child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10.0, top: 20),
                    child: Text(
                      'ac;pic',
                      style: kAcpicMain,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 30),
                    child: Text(
                      'A home for your pictures',
                      style: kSubtitle,
                    ),
                  ),
                  TextField(
                    keyboardType: TextInputType.emailAddress,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    enableSuggestions: true,
                    decoration: InputDecoration(
                      hintText: 'Username or email',
                      contentPadding: EdgeInsets.symmetric(
                          vertical: 10.0, horizontal: 20.0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(100)),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 20),
                    child: TextField(
                      autofocus: true,
                      obscureText: true,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        contentPadding: EdgeInsets.symmetric(
                            vertical: 10.0, horizontal: 20.0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(100)),
                        ),
                      ),
                    ),
                  ),
                  RoundedButton(
                    title: 'Log In',
                    colour: kAltoBlue,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            return StartUpload();
                          },
                        ),
                      );
                      // This makes the keyboard disappear
                      FocusManager.instance.primaryFocus?.unfocus();
                    },
                  ),
                  Builder(
                    builder: (context) => Flexible(
                      flex: 2,
                      fit: FlexFit.loose,
                      child: TextButton(
                        onPressed: () {
                          SnackbarGlobal.buildSnackbar(
                              context, 'Coming soon, hang tight!', 'green');
                          // This makes the keyboard disappear
                          FocusManager.instance.primaryFocus?.unfocus();
                        },
                        child: Text(
                          'Forgot password?',
                          style: kPlainHypertext,
                        ),
                      ),
                    ),
                  ),
                  Flexible(
                    flex: 2,
                    fit: FlexFit.loose,
                    child: TextButton(
                      onPressed: () {
                        showDialog(
                            context: context,
                            builder: (context) {
                              return Platform.isIOS
                                  ? CupertinoInvite()
                                  : AndroidInvite();
                            });
                      },
                      child: Text(
                        'Don\'t have an account? Request an invite.',
                        style: kPlainHypertext,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ))),
    );
  }
}
