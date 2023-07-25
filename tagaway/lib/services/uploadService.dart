import 'dart:io';
import 'package:photo_manager/photo_manager.dart';
import 'package:collection/collection.dart';
import 'package:tagaway/ui_elements/constants.dart';

import 'package:tagaway/services/tools.dart';
import 'package:tagaway/services/authService.dart';
import 'package:tagaway/services/storeService.dart';
import 'package:tagaway/services/tagService.dart';
import 'package:flutter_isolate/flutter_isolate.dart';

class UploadService {
   UploadService._privateConstructor ();
   static final UploadService instance = UploadService._privateConstructor ();

   var uploadQueue = [];
   var upload      = {};
   var localPivs   = [];
   var localPivsLoaded = false;
   bool uploading  = false;
   var recomputeLocalPages = true;

   startUpload () async {
      // Reuse existing upload if it has been used less than nine minutes ago.
      if (upload ['time'] != null && (upload ['time'] + 9 * 60 * 1000 >= now ())) {
         upload ['time'] = now ();
         return upload ['id'];
      }
      var response = await ajax ('post', 'upload', {'op': 'start', 'tags': [], 'total': 1});
      upload = {'id': response ['body'] ['id'], 'time': now ()};
      return upload ['id'];
      // TODO: handle errors
   }

   completeUpload () async {
      if (upload ['time'] == null) return;
      var response = await ajax ('post', 'upload', {'op': 'complete', 'id': upload ['id']});
      upload = {};
      return response ['code'];
   }

   uploadPiv (dynamic piv) async {
      File file = await piv.originFile;

      var response = await ajaxMulti ('piv', {
         // TODO: handle error in startUpload
         'id':           await startUpload (),
         'tags':         '[]',
         'lastModified': piv.createDateTime.millisecondsSinceEpoch
      }, file.path);

      if (! AuthService.instance.isLogged ()) return;

      if (response ['code'] == 200) {
         StoreService.instance.set ('pivMap:'  + piv.id, response ['body'] ['id']);
         StoreService.instance.set ('rpivMap:' + response ['body'] ['id'], piv.id);
         // We set the hashMap in case it wasn't already locally set. If we overwrite it, it shouldn't matter, since the server and the client compute them in the same way.
         StoreService.instance.set ('hashMap:' + piv.id, response ['body'] ['hash']);
         var pendingTags = StoreService.instance.get ('pendingTags:' + piv.id);
         if (pendingTags != '') {
            for (var tag in pendingTags) {
               // We don't await for this, we keep on going to fire the tag operations as quickly as possible without delaying further uploads.
               TagService.instance.tagPivById (response ['body'] ['id'], tag, false);
            }
         }
         StoreService.instance.remove ('pendingTags:' + piv.id, 'disk');
         if (StoreService.instance.get ('pendingDeletion:' + piv.id)) {
            deleteLocalPivs ([piv.id]);
            StoreService.instance.remove ('pendingDeletion:' + piv.id, 'disk');
         }
      }
      return response;
   }

   updateUploadQueue () async {
      var dryUploadQueue = [];
      uploadQueue.forEach ((v) => dryUploadQueue.add (v.id));
      StoreService.instance.set ('uploadQueue', dryUploadQueue, 'disk');
   }

   // Calls with piv argument come from another service
   // Calls with no piv argument are recursive to keep the ball rolling
   // Recursive calls do not get blocked by the `uploading` flag.
   queuePiv (dynamic piv) async {
      if (piv != null) {
         // If not set, we set pivMap:ID to `true` to mark the piv as uploaded already, to avoid confusion to the user.
         if (StoreService.instance.get ('pivMap:' + piv.id) == '') {
            StoreService.instance.set ('pivMap:' + piv.id, true);
         }
         bool pivAlreadyInQueue = false;
         uploadQueue.forEach ((queuedPiv) {
            if (piv.id == queuedPiv.id) pivAlreadyInQueue = true;
         });
         if (pivAlreadyInQueue) return;
         uploadQueue.add (piv);
         updateUploadQueue ();

         if (uploading) return;
         uploading = true;
      }

      var nextPiv = uploadQueue [0];
      // If we don't have an entry in pivMap for this piv, we haven't already uploaded it earlier, so we upload it now. `true` entries are mere placeholders.
      if (['', true].contains (StoreService.instance.get ('pivMap:' + nextPiv.id))) {
         // If an upload takes over 9 minutes, it will become stalled and we'll simply create a new one. The logic in `startUpload` takes care of this. So we don't need to create a `setInterval` that keeps on sending `start` ops to POST /upload.
         var result = await uploadPiv (nextPiv);
         if (! AuthService.instance.isLogged ()) return;
         if (result ['code'] == 200) {
            // Success, remove from queue and keep on going.
            uploadQueue.removeAt (0);
            updateUploadQueue ();
         }
         else if (result ['code'] > 400) {
            // Invalid piv, remove from queue and keep on going
            uploadQueue.removeAt (0);
            updateUploadQueue ();
            // TODO: report error
         }
         else if (result ['code'] == 409) {
            if (result ['body'] ['error'] == 'capacity') {
                // No space left, stop uploading all pivs and clear the queue
               uploadQueue = [];
               updateUploadQueue ();
               return uploading = false;
               // TODO: report
            }
            else {
               // Issue with the upload group, reinitialize the upload object and retry this piv
               upload ['time'] = null;
               return queuePiv (null);
            }
         }
         else {
           // Server error, connection error or unexpected error. Stop all uploads but do not clear the queue.
           return uploading = false;
           // TODO: report
         }
      }
      else {
         uploadQueue.removeAt (0);
         updateUploadQueue ();
      }

      if (uploadQueue.length == 0) {
         // TODO: handle error in completeUpload
         await completeUpload ();
         return uploading = false;
      }

      // Recursive call to keep the ball rolling since we have further pivs in the queue
      queuePiv (null);
   }

   loadLocalPivs ([reload = false]) async {

      FilterOptionGroup makeOption () {
         return FilterOptionGroup ()..addOrderOption (const OrderOption (type: OrderOptionType.createDate, asc: false));
      }

      final option = makeOption ();
      // Set onlyAll to true, to fetch only the 'Recent' album which contains all the photos/videos in the storage
      final albums = await PhotoManager.getAssetPathList (onlyAll: true, filterOption: option);
      if (albums.length == 0) return localPivsLoaded = true;
      final recentAlbum = albums.first;

      localPivs = await recentAlbum.getAssetListRange (start: 0, end: 1000000);
      localPivsLoaded = true;

      StoreService.instance.set ('countLocal', localPivs.length);

      for (var piv in localPivs) {
         StoreService.instance.set ('pivDate:' + piv.id, piv.createDateTime.millisecondsSinceEpoch);
      }

      if (! reload) {
         // Check if we have uploads we should revive
         reviveUploads ();

         // Compute hashes for local pivs
         computeHashes ();

         computeLocalPages ();
      }
   }

   reviveUploads () async {
      var queue = await StoreService.instance.getBeforeLoad ('uploadQueue');

      if (queue == '' || queue.length == 0) return;

      localPivs.forEach ((v) {
         if (queue.contains (v.id)) uploadQueue.add (v);
      });

      queuePiv (null);
   }

   queryHashes (dynamic hashesToQuery) async {
      var response = await ajax ('post', 'idsFromHashes', {'hashes': hashesToQuery.values.toList ()});
      // TODO: handle errors
      if (response ['code'] != 200) return {};

      var output = {};

      hashesToQuery.forEach ((localId, hash) {
         output [localId] = response ['body'] [hash];
      });
      return output;
   }

   computeHashes () async {
      // Get all hash entries and remove those that don't belong to a piv
      var localPivIds = {};
      localPivs.forEach ((v) {
         localPivIds [v.id] = true;
      });

      // We do this in a loop instead of a `forEach` to make sure that the `await` will be waited for.
      for (var k in StoreService.instance.store.keys.toList ()) {
         if (! RegExp ('^hashMap:').hasMatch (k)) continue;
         var id = k.replaceAll ('hashMap:', '');
         if (localPivIds [id] == null) await StoreService.instance.remove (k, 'disk');
      }

      // Query existing hashes
      var hashesToQuery = {};

      StoreService.instance.store.keys.toList ().forEach ((k) {
         if (! RegExp ('^hashMap:').hasMatch (k)) return;
         var id = k.replaceAll ('hashMap:', '');
         hashesToQuery [id] = StoreService.instance.get (k);
      });

      var queriedHashes = await queryHashes (hashesToQuery);

      queriedHashes.forEach ((localId, uploadedId) {
         if (uploadedId == null) return;
         StoreService.instance.set ('pivMap:'  + localId,    uploadedId);
         StoreService.instance.set ('rpivMap:' + uploadedId, localId);
      });

      // Compute hashes for local pivs that do not have them
      for (var piv in localPivs) {
         if (StoreService.instance.get ('hashMap:' + piv.id) != '') continue;
         // NOTE: in debug mode, running `flutterCompute` will trigger a general redraw.
         var hash = await flutterCompute (hashPiv, piv.id);
         StoreService.instance.set ('hashMap:' + piv.id, hash, 'disk');

         // Check if the local piv we just hashed as an uploaded counterpart
         var queriedHash = await queryHashes ({piv.id: hash});
         if (queriedHash [piv.id] != null) {
            StoreService.instance.set ('pivMap:'  + piv.id,               queriedHash [piv.id]);
            StoreService.instance.set ('rpivMap:' + queriedHash [piv.id], piv.id);
         }
      }
   }

   computeLocalPages () async {

      var t = DateTime.now ();

      // If there's no need to recompute, just await and return.
      if (! recomputeLocalPages) {
         await Future.delayed (Duration (milliseconds: 50));
         return computeLocalPages ();
      }

      recomputeLocalPages = false;

      DateTime tomorrow        = DateTime.fromMillisecondsSinceEpoch(DateTime.now().millisecondsSinceEpoch + 24 * 60 * 60 * 1000);
      tomorrow                 = DateTime (tomorrow.year, tomorrow.month, tomorrow.year);
      DateTime now             = DateTime.now ();
      DateTime today           = DateTime (now.year, now.month, now.day);
      DateTime monday          = DateTime (now.year, now.month, now.day - (now.weekday - 1));
      DateTime firstDayOfMonth = DateTime (now.year, now.month, 1);

      var pages = [['Today', today], ['This week', monday], ['This month', firstDayOfMonth]].map ((pair) {
         return {'title': pair [0], 'total': 0, 'left': 0, 'pivs': [], 'from': ms (pair [1]), 'to': ms (tomorrow)};
      }).toList ();

      var displayMode = StoreService.instance.get ('displayMode');
      var currentlyTaggingPivs = StoreService.instance.get ('currentlyTaggingPivs');
      if (currentlyTaggingPivs == '') currentlyTaggingPivs = [];

      localPivs.forEach ((piv) {
         // Piv is considered as organized if it has a matching orgMap entry or if it has a pending tag. Since we always mark as organized when tagging, the latter is qeuivalent of the former.
         // We convert the pivMap:ID to string in case it's `true` (which denotes an ongoing upload)
         var pivIsOrganized = StoreService.instance.get ('orgMap:' + StoreService.instance.get ('pivMap:' + piv.id).toString ()) != '';
         if (! pivIsOrganized) pivIsOrganized = StoreService.instance.get ('pendingTags:' + piv.id) != '';

         var pivIsCurrentlyBeingTagged = currentlyTaggingPivs.contains (piv.id);

         var showPiv = pivIsCurrentlyBeingTagged || displayMode == 'all' || ! pivIsOrganized;

         var placed = false, pivDate = piv.createDateTime;
         pages.forEach ((page) {
            if ((page ['from'] as int) <= ms (pivDate) && (page ['to'] as int) >= ms (pivDate)) {
               placed = true;
               page ['total'] = (page ['total'] as int) + 1;
               if (showPiv) (page ['pivs'] as List).add (piv);
               if (! pivIsOrganized) page ['left'] = (page ['left'] as int) + 1;
            }
         });
         if (! placed) pages.add ({
            'title': longMonthNames [pivDate.month - 1] + ' ' + pivDate.year.toString (),
            'total': 1,
            'pivs': showPiv ? [piv] : [],
            'left': pivIsOrganized ? 0 : 1,
            'from': ms (DateTime (pivDate.year, pivDate.month, 1)),
            'to':   ms (pivDate.month < 12 ? DateTime (pivDate.year, pivDate.month + 1, 1) : DateTime (pivDate.year + 1, 1, 1)) - 1
         });
      });

      if (StoreService.instance.get ('localPagesLength') != pages.length) StoreService.instance.set ('localPagesLength', pages.length);
      pages.asMap ().forEach ((index, page) {
         var existingPage = StoreService.instance.get ('localPage:' + index.toString ());
         if (existingPage == '' || ! DeepCollectionEquality ().equals (existingPage, page)) {
            StoreService.instance.set ('localPage:' + index.toString (), page);
         }
      });

      if (StoreService.instance.get ('localPagesListener') == '') {
        StoreService.instance.set ('localPagesListener', StoreService.instance.listen ([
          'pivMap:*',
          'orgMap:*',
          'pendingTags:*',
          'displayMode',
          'currentlyTaggingPivs'
         ], (v1, v2, v3, v4, v5) {
            recomputeLocalPages = true;
         }));
      }

      await Future.delayed (Duration (milliseconds: 50));
      computeLocalPages ();
   }

   deleteLocalPivs (ids) async {
      var currentlyUploading = [];
      uploadQueue.forEach ((queuedPiv) {
         if (ids.contains (queuedPiv.id)) {
            StoreService.instance.set ('pendingDeletion:' + queuedPiv.id, true, 'disk');
            ids.remove (queuedPiv.id);
         }
      });

      if (ids.length == 0) return;

      List<String> typedIds = ids.cast<String>();
      await PhotoManager.editor.deleteWithIds (typedIds);
      loadLocalPivs (true);
  }
}
