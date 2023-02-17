import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:tagaway/services/local_vars_shared_prefsService.dart';
import 'package:tagaway/ui_elements/constants.dart';

class TagService {
   TagService._privateConstructor();

   static final TagService instance = TagService._privateConstructor();

   Future <dynamic> getTags () async {
      dynamic output = {'hometags': [], 'tags': []};
      try {
         final cookie   = await SharedPreferencesService.instance.get ('cookie');
         final response = await http.get (
            Uri.parse (kAltoPicAppURL + '/tags'),
            headers: <String, String> {'cookie': cookie}
         );
         if (response.statusCode == 200) {
            dynamic body = jsonDecode (response.body);
            SharedPreferencesService.instance.set ('hometags', body ['hometags']);
            SharedPreferencesService.instance.set ('tags',     body ['tags']);
            output = {'hometags': body ['hometags'], 'tags': body ['tags']};
         }
         return output;
      } on SocketException catch (_) {
         return output;
      }
   }

   Future <dynamic> editHometags (dynamic hometags) async {
      try {
         final csrf     = await SharedPreferencesService.instance.get ('csrf');
         final cookie   = await SharedPreferencesService.instance.get ('cookie');
         final response = await http.post (
            Uri.parse (kAltoPicAppURL + '/hometags'),
            headers: <String, String> {
               'Content-Type': 'application/json; charset=UTF-8',
               'cookie':       cookie
            },
            body: jsonEncode (<String, dynamic> {
               'csrf':     csrf,
               'hometags': hometags
            }),
         );
         if (response.statusCode == 200) {
            await this.getTags ();
            return 1;
         }
         return -1;
      } on SocketException catch (_) {
         return -1;
      }
   }

   Future <dynamic> addHometag (String tag) async {
      dynamic hometags = await SharedPreferencesService.instance.get ('hometags');
      if (hometags.contains (tag)) return 0;
      hometags.add (tag);
      return this.editHometags (hometags);
   }

   Future <dynamic> removeHometag (String tag) async {
      dynamic hometags = await SharedPreferencesService.instance.get ('hometags');
      if (! hometags.contains (tag)) return 0;
      hometags.remove (tag);
      return this.editHometags (hometags);
   }
}
