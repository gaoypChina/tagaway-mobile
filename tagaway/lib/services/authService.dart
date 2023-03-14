import 'package:tagaway/ui_elements/constants.dart';
import 'package:tagaway/services/storeService.dart';

class AuthService {
   AuthService._privateConstructor ();
   static final AuthService instance = AuthService._privateConstructor ();

   Future <int> login (String username, String password, int timezone) async {
      var response = await ajax ('post', 'auth/login', {'username': username, 'password': password, 'timezone': timezone});
      if (response ['code'] == 200) {
         StoreService.instance.set ('cookie', response ['headers'] ['set-cookie']!);
         StoreService.instance.set ('csrf',   response ['body']    ['csrf']);
         StoreService.instance.set ('recurringUser', true);
      }
      return response ['code'];
   }

   Future <int> deleteAccount () async {
      var response = await ajax ('post', 'auth/delete', {});
      return response ['code'];
   }

   Future <int> changePassword (String old, String nEw, String repeat) async {
      if (nEw != repeat) return 1;
      var response = await ajax ('post', 'auth/changePassword', {'old': old, 'new': nEw});
      return response ['code'];
   }

}
