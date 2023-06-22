import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tagaway/services/tools.dart';

class StoreService {
  late SharedPreferences prefs;
  getPrefs () async {
     prefs = await SharedPreferences.getInstance ();
     await cleanupDeprecatedKeys ();
  }

  StoreService._privateConstructor () {
     getPrefs ();
  }
  static final StoreService instance = StoreService._privateConstructor ();

  bool showLogs = false;
  bool loaded   = false;

  var updateStream = StreamController<String>.broadcast ();

  var store = {};

   listen (dynamic list, Function fun) {
      Function updater = () async {
         var results = [];
         list.forEach ((v) => results.add (StoreService.instance.get (v)));
         Function.apply (fun, results);
      };
      // Run updater once to fetch current values
      updater ();
      // Register listener and return its cancel method
      return updateStream.stream.listen ((key) async {
         if (list.contains (key)) return updater ();
      }).cancel;
   }

   reset () async {
     store = {};
     // We load prefs directly to have them already available.
     if (showLogs) debug (['STORE RESET']);
     var prefs = await SharedPreferences.getInstance ();
     await prefs.clear ();
   }

   // This function is called by main.dart to recreate the in-memory store
   load ([var resetKeys]) async {
      if (resetKeys != null) {
         await reset ();
         // Wait a full second until changes are flushed to disk
         await Future.delayed (Duration (seconds: 1));
      }
      // We load prefs directly to have them already available.
      var prefs = await SharedPreferences.getInstance ();
      var keys = await prefs.getKeys ().toList ();
      keys.sort ();
      for (var k in keys) {
         store [k] = await jsonDecode (prefs.getString (k) ?? '""');
      };
      if (showLogs) keys.forEach ((k) => debug (['STORE LOAD', k, jsonEncode (store [k])]));
      if (showLogs) debug (['STORE LOAD COMPLETE']);
      loaded = true;
   }

   // This function need not be awaited for setting the in-memory key, only if you want to await until the key is persisted to disk
   // It takes 'disk' as a third argument if you want the value to also be persisted to disk
   set (String key, dynamic value, [String disk = '', String mute = '']) async {
      if (showLogs) debug (['STORE SET', disk == 'disk' ? 'MEM & DISK' : 'MEM', key, jsonEncode (value)]);
      store [key] = value;
      if (mute != 'mute') updateStream.add (key);
      // Some fields should not be stored, we want these to be in-memory only
      if (disk == 'disk') await prefs.setString (key, jsonEncode (value));
   }

   get (String key) {
      var value = store [key] == null ? '' : store [key];
      if (showLogs) debug (['STORE GET', key, jsonEncode (value)]);
      return value;
   }

   // Necessary function if you're trying to get things before the prefs get initialized
   getBeforeLoad (String key) async {
      if (! loaded) {
         // We load prefs directly to have them already available.
         var prefs = await SharedPreferences.getInstance ();
         var value = await prefs.getString (key);
         var decoded = jsonDecode (value ?? '""');
         if (showLogs) debug (['STORE GET', key, jsonEncode (decoded)]);
         return decoded;
      }
      var value = store [key] == null ? '' : store [key];
      if (showLogs) debug (['STORE GET', key, jsonEncode (value)]);
      return value;
   }

   remove (String key, [String disk = '']) async {
      if (RegExp ('^[^:]+:\\*').hasMatch (key)) {
         for (var k in store.keys) {
            if (RegExp (key.split (':') [0]).hasMatch (k)) await remove (k, disk);
         }
         return;
      }
      if (showLogs) debug (['STORE REMOVE', key]);
      store [key] = '';
      updateStream.add (key);
      if (disk == 'disk') await prefs.remove (key);
   }

   reportPreviousError () async {
    var previousError = await getBeforeLoad ('previousError');
    if (previousError != '') {
      ajax ('post', 'error', previousError);
      remove ('previousError', 'disk');
    }
  }

   cleanupDeprecatedKeys () async {
      var keys = await prefs.getKeys ().toList ();
      // We no longer store pivMap: and rpivMap: keys on disk
      for (var k in keys) {
         if (RegExp ('^r?pivMap:').hasMatch (k)) await prefs.remove (k);
      };
   }

}
