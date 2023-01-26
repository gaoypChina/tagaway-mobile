// IMPORT FLUTTER PACKAGES
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
//IMPORT SERVICES
import 'package:tagaway/services/local_vars_shared_prefsService.dart';
// IMPORT UI ELEMENTS
import 'package:tagaway/ui_elements/constants.dart';

class LogInService {
  LogInService._privateConstructor();

  static final LogInService instance = LogInService._privateConstructor();

  Future<int> createAlbum(
      String username, String password, dynamic timezone) async {
    try {
      final response = await http.post(
        Uri.parse(kAltoPicAppURL + '/auth/login'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'username': username,
          'password': password,
          'timezone': timezone
        }),
      );
      if (response.statusCode == 200) {
        SharedPreferencesService.instance
            .setStringValue('cookie', response.headers['set-cookie']!);
        SharedPreferencesService.instance.setStringValue(
            'csrf',
            jsonDecode(response.body).toString().substring(
                7, jsonDecode(response.body).toString().indexOf('}')));
        // print(response.statusCode);
        return response.statusCode;
      } else {
        return response.statusCode;
      }
    } on SocketException catch (_) {
      return 0;
    }
  }
}