import 'package:acpic/services/checkPermission.dart';
import 'package:flutter/material.dart';
//IMPORT SCREENS
import 'package:acpic/screens/grid.dart';
import 'package:acpic/main.dart';

class LifeCycleManager extends StatefulWidget {
  final Widget child;
  final ValueChanged<bool> resumed;
  const LifeCycleManager({Key key, this.child, this.resumed}) : super(key: key);

  @override
  _LifeCycleManagerState createState() => _LifeCycleManagerState();
}

class _LifeCycleManagerState extends State<LifeCycleManager>
    with WidgetsBindingObserver {
  bool resumed = false;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);

    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // print('state = $state');
    if (state == AppLifecycleState.resumed) {
      setState(() {
        resumed = true;
      });
      checkPermission(context).then((value) {
        if (resumed == true && value == 'granted') {
          print('send to grid');
        } else {
          print('Stay here');
        }
      });
      print('resumed $resumed');
    } else {
      resumed = false;
      // print('resumed $resumed');
    }
  }

  @override
  Widget build(BuildContext context) {
    print('I am in the LifeCycleManager Build and resumed is $resumed');
    return Container(
      child: widget.child,
    );
  }
}
