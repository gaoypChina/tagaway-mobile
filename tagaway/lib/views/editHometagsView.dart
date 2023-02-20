import 'package:flutter/material.dart';

import 'package:tagaway/ui_elements/constants.dart';
import 'package:tagaway/ui_elements/material_elements.dart';

import 'package:tagaway/services/storeService.dart';
import 'package:tagaway/services/tagService.dart';

class EditHometagsView extends StatefulWidget {
  const EditHometagsView({Key? key}) : super(key: key);

  @override
  State<EditHometagsView> createState() => _EditHometagsViewState();
}

class _EditHometagsViewState extends State<EditHometagsView> {
   List hometags = [];

   void initState () {
      super.initState ();
      StoreService.instance.updateStream.stream.listen ((value) async {
         if (value != 'hometags') return;
         dynamic Hometags = await StoreService.instance.get ('hometags');
         setState (() {
            hometags = Hometags;
         });
      });
      // TODO: handle error
      TagService.instance.getTags ();
   }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: kAltoBlue),
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(top: 18, left: 12),
          child: GestureDetector(
              onTap: () {}, child: const Text('Done', style: kDoneEditText)),
        ),
        title: const Text('Your home tags', style: kSubPageAppBarTitle),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () {}),
        ],
      ),
      body: SafeArea(
          child: Padding(
        padding: const EdgeInsets.only(left: 12, right: 12, top: 5),
        child: ListView(
          // shrinkWrap: true,
          children: [
            for (var v in hometags) EditTagListElement (tagColor: tagColor (v), tagName: v, onTapOnRedCircle: () {
               // We need to wrap this in another function, otherwise it gets executed on view draw. Madness.
               return () {
                  TagService.instance.editHometags (v, false);
               };
            }, onTagElementVerticalDragDown: () {})
          ],
        ),
      )),
    );
  }
}
