import 'package:shared_preferences/shared_preferences.dart';

import 'package:tagaway/services/storeService.dart';
import 'package:tagaway/services/uploadService.dart';
import 'package:tagaway/ui_elements/constants.dart';

class TagService {
  TagService._privateConstructor();
  static final TagService instance = TagService._privateConstructor();

  getTags() async {
    var response = await ajax('get', 'tags');
    if (response['code'] == 200) {
      StoreService.instance.set('hometags', response['body']['hometags']);
      StoreService.instance.set('tags', response['body']['tags']);
      var usertags = [];
      response['body']['tags'].forEach((tag) {
        if (!RegExp('^[a-z]::').hasMatch(tag)) usertags.add(tag);
      });
      StoreService.instance.set('usertags', usertags);
    }
    // TODO: handle errors
    return response['code'];
  }

  editHometags(String tag, bool add) async {
    // Refresh hometag list first in case it was updated in another client
    await getTags ();
    var hometags = StoreService.instance.get('hometags');
    if (hometags == '') hometags = [];
    if ((add && hometags.contains(tag)) || (!add && !hometags.contains(tag)))
      return;
    add ? hometags.add(tag) : hometags.remove(tag);
    var response = await ajax('post', 'hometags', {'hometags': hometags});
    if (response['code'] == 200) {
      await getTags();
    }
    // TODO: handle errors
    return response['code'];
  }

  tagPivById(String id, String tag, bool del) async {
    var hometags = StoreService.instance.get ('hometags');
    if (! del && (hometags == '' || hometags.isEmpty)) await editHometags (tag, true);
    var response = await ajax('post', 'tag', {'tag': tag, 'ids': [id], 'del': del, 'autoOrganize': true});
    if (response['code'] == 200) {
       await queryPivs (StoreService.instance.get ('queryTags'));
       var total = StoreService.instance.get('queryResult')['total'];
       if (total == 0 && StoreService.instance.get ('queryTags').length > 0) {
         StoreService.instance.set ('queryTags', []);
         await queryPivs (StoreService.instance.get ('queryTags'));
       }
    }
    return response['code'];
  }

  tagPiv (dynamic assetOrPiv, String tag, String type) async {
    String id = type == 'uploaded' ? assetOrPiv['id'] : assetOrPiv.id;
    String pivId = type == 'uploaded' ? id : StoreService.instance.get ('pivMap:' + id);
    bool   del   = StoreService.instance.get ('tagMap:' + id) != '';
    StoreService.instance.set ('tagMap:' + id, del ? '' : true);
    StoreService.instance.set ('taggedPivCount' + (type == 'local' ? 'Local' : 'Uploaded'), StoreService.instance.get ('taggedPivCount' + (type == 'local' ? 'Local': 'Uploaded')) + (del ? -1 : 1));

    if (pivId != '') {
      var code = await tagPivById(pivId, tag, del);
      if (type == 'uploaded') return;
      // TODO: add error handling for non 200 (with exception to 404 for local, which is handled below)

      // If piv still exists, we are done. Otherwise, we need to re-upload it.
      if (code == 200) return;
      if (code == 404) {
         StoreService.instance.remove ('pivMap:' + id, 'disk');
         StoreService.instance.remove ('rpivMap:' + pivId, 'disk');
      }
    }
    UploadService.instance.queuePiv (assetOrPiv);
    var pendingTags = StoreService.instance.get ('pending:' + id);
    if (pendingTags == '') pendingTags = [];
    if (del) pendingTags.remove (tag);
    else     pendingTags.add    (tag);
    StoreService.instance.set ('pendingTags:' + id, pendingTags, 'disk');
  }

  getTaggedPivs (String tag, String type) async {
    var response = await ajax('post', 'query', {
      'tags': [tag],
      'sort': 'newest',
      'from': 1,
      'to': 1000,
      'idsOnly': true
    });
    await StoreService.instance.remove ('tagMap:*');
    int count = 0;
    var queryIds;
    if (type == 'uploaded') queryIds = StoreService.instance.get ('queryResult') ['pivs'].map ((v) => v ['id']);
    response ['body'].forEach ((v) {
      if (type == 'uploaded') {
         if (! queryIds.contains (v)) return;
         count += 1;
         return StoreService.instance.set ('tagMap:' + v, true);
      }

      var id = StoreService.instance.get ('rpivMap:' + v);
      if (id == '') return;
      StoreService.instance.set ('tagMap:' + id, true);
      count += 1;
    });
    StoreService.instance.set ('taggedPivCount' + (type == 'local' ? 'Local' : 'Uploaded'), count);
  }

   getLocalTimeHeader () {
      var monthNames  = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      var localCount  = {};
      var remoteCount = {};
      var lastPivInMonth = {};
      var output      = [];
      var min = now (), max = 0;

      StoreService.instance.store.keys.toList ().forEach ((k) {
        // pivDate entries exist for *all* local pivs, whereas pivMap entries exist only for local pivs that were already uploaded
        if (! RegExp ('^pivDate:').hasMatch (k)) return;

        var id   = k.replaceAll ('pivDate:', '');
        var date = StoreService.instance.get (k);
        if (date < min) min = date;
        if (date > max) max = date;

        var Date        = new DateTime.fromMillisecondsSinceEpoch (date);
        var dateKey = Date.year.toString () + ':' + Date.month.toString ();
        if (localCount  [dateKey] == null) localCount  [dateKey] = 0;
        if (remoteCount [dateKey] == null) remoteCount [dateKey] = 0;
        if (lastPivInMonth [dateKey] == null) lastPivInMonth [dateKey] = {};

        localCount [dateKey] += 1;
        if (StoreService.instance.get ('pivMap:' + id) != '') remoteCount [dateKey] += 1;
        if (lastPivInMonth [dateKey] ['id'] == null || lastPivInMonth [dateKey] ['date'] < date) {
           lastPivInMonth [dateKey] = {'id': id, 'date': date};
        }
      });

      var empty = false;
      // No local pivs, show current semester as empty.
      if (max == 0) {
         max = now ();
         min = now ();
         empty = true;
      }

      var fromYear  = DateTime.fromMillisecondsSinceEpoch (min).year;
      var toYear    = DateTime.fromMillisecondsSinceEpoch (max).year;
      var fromMonth = DateTime.fromMillisecondsSinceEpoch (min).month;
      var toMonth   = DateTime.fromMillisecondsSinceEpoch (max).month;
      fromMonth = fromMonth < 7 ? 1  : 7;
      toMonth   = toMonth   > 6 ? 12 : 6;

      for (var year = fromYear; year <= toYear; year++) {
         for (var month = (year == fromYear ? fromMonth : 1); month <= (year == toYear ? toMonth : 12); month++) {
            var dateKey = year.toString () + ':' + month.toString ();
            if (localCount  [dateKey] == null) localCount  [dateKey] = 0;
            if (remoteCount [dateKey] == null) remoteCount [dateKey] = 0;

            if (localCount [dateKey] == 0)                         output.add ([year, monthNames [month - 1], 'white']);
            else if (localCount [dateKey] > remoteCount [dateKey]) output.add ([year, monthNames [month - 1], 'gray', lastPivInMonth [dateKey] ['id']]);
            else                                                   output.add ([year, monthNames [month - 1], 'green', lastPivInMonth [dateKey] ['id']]);
         }
      };

      var semesters = [[]];
      output.forEach ((month) {
         var lastSemester = semesters [semesters.length - 1];
         if (lastSemester.length < 6) lastSemester.add (month);
         else semesters.add ([month]);
      });

      // Filter out ronin semesters if we have pivs
      if (! empty) {
         semesters = semesters.where ((semester) {
            var nonWhite = 0;
            semester.forEach ((month) {
               if (month [2] != 'white') nonWhite++;
            });
            return nonWhite > 0;
         }).toList ();
      }

      StoreService.instance.set ('localTimeHeader', semesters);
   }

   getUploadedTimeHeader () {
      var monthNames  = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      var localCount  = {};
      var remoteCount = {};
      var lastPivInMonth = {};
      var output      = [];
      var min, max;
      var timeHeader = StoreService.instance.get ('queryResult') ['timeHeader'];
      // No uploaded pivs, return current semester as empty.
      timeHeader.keys.forEach ((v) {
         var dates = v.split (':');
         dates = [int.parse (dates [0]), int.parse (dates [1])];
         // Round down to the beginning of the semester
         if (dates [1] < 7) dates [1] = 1;
         else               dates [1] = 7;
         if (min == null) min = dates;
         if (max == null) max = dates;
         if (dates [0] <= min [0] && dates [1] <= min [1]) min = dates;
         if (dates [0] >= max [0] && dates [1] >= max [1]) max = dates;
      });
      if (timeHeader.keys.length == 0) {
        max = [DateTime.now().year, DateTime.now ().month > 6 ? 12 : 6];
        min = [DateTime.now().year, DateTime.now ().month < 7 ? 1 : 7];
      }
      for (var year = min [0]; year <= max [0]; year++) {
         for (var month = 1; month <= 12; month++) {
           var dateKey = year.toString () + ':' + month.toString ();
           if (timeHeader [dateKey] == null)       output.add ([year, monthNames [month - 1], 'white']);
           // TODO: add last piv in month or figure out alternative way to jump
           else if (timeHeader [dateKey] == false) output.add ([year, monthNames [month - 1], 'gray']);
           else                                    output.add ([year, monthNames [month - 1], 'green']);
         }
      }
      var semesters = [[]];
      output.forEach ((month) {
         var lastSemester = semesters [semesters.length - 1];
         if (lastSemester.length < 6) lastSemester.add (month);
         else semesters.add ([month]);
      });

      // Filter out ronin semesters if we have pivs
      if (timeHeader.keys.length > 0) {
         semesters = semesters.where ((semester) {
            var nonWhite = 0;
            semester.forEach ((month) {
               if (month [2] != 'white') nonWhite++;
            });
            return nonWhite > 0;
         }).toList ();
      }


      StoreService.instance.set ('uploadedTimeHeader', semesters);
   }

   queryPivs (dynamic tags) async {
    var response = await ajax('post', 'query', {
      'tags': tags,
      'sort': 'newest',
      'from': 1,
      'to': 1000,
      'timeHeader': true
    });
    if (response ['code'] == 200) {
      StoreService.instance.set('queryResult', response ['body']);
      getUploadedTimeHeader();
      await StoreService.instance.remove ('orgMap:*');

      var orgIds;

      if (! tags.contains ('o::')) {
         response = await ajax('post', 'query', {
           'tags': [...tags]..addAll (['o::']),
           'sort': 'newest',
           'from': 1,
           'to': 1000,
           'idsOnly': true
         });
         if (response ['code'] == 200) {
            orgIds = response['body'];
         }
         else orgIds = [];
      }
      else orgIds = response ['body'] ['pivs'].map ((v) => v['id']);

      orgIds.forEach ((v) {
         StoreService.instance.set('orgMap:' + v, true);
      });
    }
    // HANDLE ERRORS
    return {'code': response ['code'], 'body': response ['body']};
  }

  toggleQueryTag (String tag) {
    var queryTags = StoreService.instance.get ('queryTags');
    if (queryTags.contains (tag)) queryTags.remove (tag);
    else                          queryTags.add (tag);
    StoreService.instance.set ('queryTags', queryTags);
  }

  deletePiv (String id) async {
    // TODO: Why do we need to pass 'csrf' here? We don't do it on any other ajax calls! And yet, if we don't, the ajax call fails with a type error. Madness.
    var response = await ajax('post', 'delete', {'ids': [id], 'csrf': 'foo'});
    var localPivId = StoreService.instance.get ('rpivMap:' + id);
    if (localPivId != '') {
      StoreService.instance.remove ('pivMap:' + localPivId, 'disk');
      StoreService.instance.remove ('rpivMap:' + id, 'disk');
    }
    if (response['code'] == 200) {
       await queryPivs (StoreService.instance.get ('queryTags'));
       var total = StoreService.instance.get('queryResult')['total'];
       if (total == 0 && StoreService.instance.get ('queryTags').length > 0) {
         StoreService.instance.set ('queryTags', []);
         await queryPivs (StoreService.instance.get ('queryTags'));
       }
    }
    return response['code'];
  }

}
