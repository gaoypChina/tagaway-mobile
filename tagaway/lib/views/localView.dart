import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:tagaway/services/sizeService.dart';
import 'package:tagaway/services/storeService.dart';
import 'package:tagaway/services/tagService.dart';
import 'package:tagaway/services/tools.dart';
import 'package:tagaway/services/uploadService.dart';
import 'package:tagaway/ui_elements/constants.dart';
import 'package:tagaway/ui_elements/material_elements.dart';
import 'package:tagaway/views/localGridItemView.dart';

class LocalYear extends StatefulWidget {
  const LocalYear({Key? key}) : super(key: key);

  @override
  State<LocalYear> createState() => _LocalYearState();
}

class _LocalYearState extends State<LocalYear> {
  dynamic cancelListener;
  dynamic year = '';

  @override
  void initState() {
    super.initState();
    cancelListener = StoreService.instance.listen([
      'localYear',
    ], (v1) {
      setState(() => year = v1);
    });
  }

  @override
  void dispose() {
    super.dispose();
    cancelListener();
  }

  @override
  Widget build(BuildContext context) {
    return Text(year.toString(),
        textAlign: TextAlign.center, style: kLocalYear);
  }
}

class LocalView extends StatefulWidget {
  static const String id = 'local';

  const LocalView({Key? key}) : super(key: key);

  @override
  State<LocalView> createState() => _LocalViewState();
}

class _LocalViewState extends State<LocalView> {
  dynamic cancelListener;
  final TextEditingController searchTagController = TextEditingController();
  final TextEditingController renameTagController = TextEditingController();

  final PageController controller = PageController();
  dynamic usertags = [];
  String currentlyTagging = '';
  bool swiped = false;
  dynamic startTaggingModal = '';

  String renameTagLocal = '';
  String deleteTagLocal = '';

  bool currentlyDeleting = false;
  bool currentlyDeletingModal = false;

  dynamic localPagesLength = 0;

  // When clicking on one of the buttons of this widget, we want the ScrollableDraggableSheet to be opened. Unfortunately, the methods provided in the controller for it (`animate` and `jumpTo`) change the scroll position of the sheet, but not its height.
  // For this reason, we need to set the `currentScrollableSize` directly. This is not a clean solution, and it lacks an animation. But it's the best we've come up with so far.
  // For more info, refer to https://github.com/flutter/flutter/issues/45009
  double initialScrollableSize =
      StoreService.instance.get('initialScrollableSize');
  double currentScrollableSize =
      StoreService.instance.get('initialScrollableSize');

  @override
  void initState() {
    super.initState();
    cancelListener = StoreService.instance.listen([
      'usertags',
      'currentlyTaggingLocal',
      'swipedLocal',
      'tagFilterLocal',
      'startTaggingModal',
      'renameTagLocal',
      'deleteTagLocal',
      'localPagesLength',
      'currentlyDeletingLocal',
      'currentlyDeletingModalLocal'
    ], (v1, v2, v3, v4, v5, v6, v7, v8, v9, v10) {
      var currentView = StoreService.instance.get('currentIndex');
      // Invoke the service only if uploaded is not the current view
      if (v2 != '' && currentView != 2)
        TagService.instance.getTaggedPivs(v2, 'local');
      setState(() {
        if (v1 != '') {
          var filter = v4;
          var lastNTags = StoreService.instance.get('lastNTags');
          if (lastNTags == '') lastNTags = [];
          usertags = List.from(lastNTags)
            ..addAll(v1.where((tag) => !lastNTags.contains(tag)));
          usertags = usertags
              .where(
                  (tag) => RegExp(filter, caseSensitive: false).hasMatch(tag))
              .toList();
          if (filter != '' && !usertags.contains(filter))
            usertags.insert(0, filter + ' (new tag)');
        }
        if (currentView != 2) {
          currentlyTagging = v2;
          if (v3 != '') swiped = v3;
          if (swiped == false) {
            FocusManager.instance.primaryFocus?.unfocus();
          }
          if (swiped == false && currentScrollableSize > initialScrollableSize)
            currentScrollableSize = initialScrollableSize;
          if (swiped == true && currentScrollableSize < 0.77)
            currentScrollableSize = 0.77;
          startTaggingModal = v5;
          renameTagLocal = v6;
          if (renameTagLocal != '') renameTagController.text = renameTagLocal;
          deleteTagLocal = v7;
          localPagesLength = v8;
          currentlyDeleting = v9 != '';
          currentlyDeletingModal = v10 != '';
        }
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    searchTagController.dispose();
    renameTagController.dispose();
    controller.dispose();
    cancelListener();
  }

  bool searchTag(String query) {
    StoreService.instance.set('tagFilterLocal', query);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    return PageView.builder(
      reverse: true,
      controller: controller,
      itemCount: localPagesLength == '' ? 0 : localPagesLength,
      pageSnapping: true,
      itemBuilder: (BuildContext context, int index) {
        return Stack(
          children: [
            Grid(localPagesIndex: index),
            TopRow(
                localPagesIndex: index),
            Visibility(
                visible: currentlyTagging != '' || currentlyDeleting,
                child: Align(
                    alignment: const Alignment(0.8, .9),
                    child: FloatingActionButton.extended(
                      onPressed: () {
                        if (currentlyTagging != '') {
                          StoreService.instance.set('swipedLocal', false);
                          StoreService.instance
                              .set('currentlyTaggingLocal', '');
                          StoreService.instance.set('tagFilterLocal', '');
                          StoreService.instance.remove('currentlyTaggingPivs');
                          searchTagController.clear();
                          // We update the tag list in case we just created a new one.
                          TagService.instance.getTags();
                          // We update the list of organized pivs for those uploaded pivs that have a local counterpart
                          UploadService.instance.queryOrganizedIds ();
                        } else {
                          if (StoreService.instance
                                  .get('currentlyDeletingPivsLocal') !=
                              '') {
                            StoreService.instance
                                .set('currentlyDeletingModalLocal', true);
                          } else {
                            StoreService.instance
                                .remove('currentlyDeletingLocal');
                          }
                        }
                      },
                      backgroundColor: currentlyDeleting ? kAltoRed : kAltoBlue,
                      label: const Text('Done', style: kSelectAllButton),
                      icon: const Icon(Icons.done),
                    ))),
            Visibility(
                visible: currentlyTagging == '' && !currentlyDeleting,
                child: StartTaggingButton(
                    buttonKey: const Key('local-start-tagging'),
                    buttonText: 'Start Tagging',
                    onPressed: () {
                      StoreService.instance.set('swipedLocal', true);
                      StoreService.instance.set('startTaggingModal', false);
                    })),
            Visibility(
                visible: currentlyTagging == '' && !currentlyDeleting,
                child: DeleteButton(
                  onPressed: () {
                    // We need to wrap this in another function, otherwise it gets executed on view draw. Madness.
                    return () {
                      StoreService.instance.set('currentlyDeletingLocal', true);
                    };
                  },
                )),
            Visibility(
                visible: currentlyTagging == '',
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox.expand(
                      child:
                          NotificationListener<DraggableScrollableNotification>(
                    onNotification: (state) {
                      if (state.extent < (initialScrollableSize + 0.0001))
                        StoreService.instance.set('swipedLocal', false);
                      if (state.extent > (0.77 - 0.0001))
                        StoreService.instance.set('swipedLocal', true);
                      StoreService.instance.set('startTaggingModal', false);
                      return true;
                    },
                    child: DraggableScrollableSheet(
                        key: Key(currentScrollableSize.toString()),
                        snap: true,
                        initialChildSize: currentScrollableSize,
                        minChildSize: initialScrollableSize,
                        maxChildSize: 0.77,
                        builder: (BuildContext context,
                            ScrollController scrollController) {
                          return ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(25),
                              topRight: Radius.circular(25),
                            ),
                            child: Container(
                              color: Colors.white,
                              child: ListView(
                                padding:
                                    const EdgeInsets.only(left: 12, right: 12),
                                controller: scrollController,
                                children: [
                                  Visibility(
                                      visible: !swiped,
                                      child: GestureDetector(
                                        onTap: () {
                                          StoreService.instance
                                              .set('swipedLocal', true);
                                          StoreService.instance
                                              .set('startTaggingModal', false);
                                        },
                                        child: const Center(
                                          child: Padding(
                                            padding: EdgeInsets.only(top: 8.0),
                                            child: FaIcon(
                                              FontAwesomeIcons.anglesUp,
                                              color: kGrey,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      )),
                                  Visibility(
                                      visible: !swiped,
                                      child: const Center(
                                        child: Padding(
                                          padding: EdgeInsets.only(
                                              top: 8.0, bottom: 8),
                                          child: Text(
                                            'Swipe to start tagging',
                                            style: kPlainTextBold,
                                          ),
                                        ),
                                      )),
                                  Visibility(
                                      visible: swiped,
                                      child: GestureDetector(
                                        onTap: () {
                                          StoreService.instance
                                              .set('swipedLocal', false);
                                        },
                                        child: const Center(
                                          child: Padding(
                                            padding: EdgeInsets.only(top: 8.0),
                                            child: FaIcon(
                                              FontAwesomeIcons.anglesDown,
                                              color: kGrey,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      )),
                                  Visibility(
                                      visible: swiped,
                                      child: const Center(
                                        child: Padding(
                                          padding: EdgeInsets.only(
                                              top: 8.0, bottom: 8),
                                          child: Text(
                                            'Tag your pics and videos',
                                            style: TextStyle(
                                                fontFamily: 'Montserrat',
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20,
                                                color: kAltoBlue),
                                          ),
                                        ),
                                      )),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: SizedBox(
                                      height: 50,
                                      child: TextField(
                                        controller: searchTagController,
                                        decoration: InputDecoration(
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  vertical: 10.0,
                                                  horizontal: 20.0),
                                          fillColor: kGreyLightest,
                                          hintText: 'Create or search a tag',
                                          hintMaxLines: 1,
                                          hintStyle: kPlainTextBold,
                                          border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide: const BorderSide(
                                                  color: kGreyDarker)),
                                          prefixIcon: const Padding(
                                            padding: EdgeInsets.only(
                                                right: 12, left: 12, top: 15),
                                            child: FaIcon(
                                              kSearchIcon,
                                              size: 16,
                                              color: kGreyDarker,
                                            ),
                                          ),
                                        ),
                                        onChanged: searchTag,
                                      ),
                                    ),
                                  ),
                                  ListView.builder(
                                      itemCount: usertags.length,
                                      padding: EdgeInsets.zero,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
                                      itemBuilder:
                                          (BuildContext context, int index) {
                                        var tag = usertags[index];
                                        var actualTag = tag;
                                        if (index == 0 &&
                                            RegExp(' \\(new tag\\)\$')
                                                .hasMatch(tag)) {
                                          actualTag = tag.replaceFirst(
                                              RegExp(' \\(new tag\\)\$'), '');
                                        }
                                        return TagListElement(
                                          // Because tags can be renamed, we need to set a key here to avoid recycling them if they change.
                                          key: Key('local-' + tag),
                                          tagColor: tagColor(actualTag),
                                          tagName: tag,
                                          view: 'local',
                                          onTap: () {
                                            // We need to wrap this in another function, otherwise it gets executed on view draw. Madness.
                                            return () {
                                              StoreService.instance.set(
                                                  'currentlyTaggingLocal',
                                                  actualTag);
                                            };
                                          },
                                        );
                                      })
                                ],
                              ),
                            ),
                          );
                        }),
                  )),
                )),
            Visibility(
                visible: startTaggingModal == true,
                child: Center(
                    child: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 12),
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: kAltoBlue,
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(
                              top: 20.0, right: 15, left: 15, bottom: 10),
                          child: Text(
                            'Your pics will backup as you tag them',
                            textAlign: TextAlign.center,
                            style: kWhiteSubtitle,
                          ),
                        ),
                        Center(
                            child: WhiteRoundedButton(
                                title: 'Start tagging',
                                onPressed: () {
                                  StoreService.instance
                                      .set('swipedLocal', true);
                                  StoreService.instance
                                      .set('startTaggingModal', false);
                                }))
                      ],
                    ),
                  ),
                ))),
            // Rename tag modal
            Visibility(
                visible: renameTagLocal != '',
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20),
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius:
                              const BorderRadius.all(Radius.circular(20)),
                          border: Border.all(color: kGreyLight, width: .5)),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 15.0),
                        child: Column(
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(
                                  right: 15, left: 15, bottom: 10),
                              child: Text(
                                'Edit tag',
                                textAlign: TextAlign.center,
                                softWrap: true,
                                style: kTaglineTextBold,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: SizedBox(
                                height: 50,
                                child: TextFormField(
                                  autofocus: true,
                                  controller: renameTagController,
                                  style: kTaglineTextBold,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 10.0, horizontal: 20.0),
                                    fillColor: kGreyLightest,
                                    hintMaxLines: 1,
                                    hintStyle: kTaglineText,
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(
                                            color: kGreyDarker)),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: double.infinity,
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: kGreyLight, width: 1),
                                  bottom:
                                      BorderSide(color: kGreyLight, width: 1),
                                ),
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  TagService.instance.renameTag(
                                      renameTagLocal, renameTagController.text);
                                  StoreService.instance
                                      .remove('renameTagLocal');
                                },
                                child: const Padding(
                                  padding:
                                      EdgeInsets.only(top: 10, bottom: 10.0),
                                  child: Text(
                                    'Done',
                                    textAlign: TextAlign.center,
                                    style: kGridTagListElementBlue,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: double.infinity,
                              child: GestureDetector(
                                onTap: () {
                                  StoreService.instance
                                      .remove('renameTagLocal');
                                },
                                child: const Padding(
                                  padding: EdgeInsets.only(top: 10.0),
                                  child: Text(
                                    'Cancel',
                                    textAlign: TextAlign.center,
                                    style: kGridTagListElement,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )),
            // Delete tag modal
            Visibility(
                visible: deleteTagLocal != '',
                child: Center(
                  child: Container(
                    height: 200,
                    width: 225,
                    decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius:
                            const BorderRadius.all(Radius.circular(20)),
                        border: Border.all(color: kGreyLight, width: .5)),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 15.0),
                      child: Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(
                                right: 15, left: 15, bottom: 10),
                            child: Text(
                              'Delete the tag ',
                              textAlign: TextAlign.center,
                              style: kTaglineText,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                right: 15, left: 15, bottom: 10),
                            child: Text(
                              deleteTagLocal + '?',
                              textAlign: TextAlign.center,
                              softWrap: true,
                              style: kTaglineTextBold,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(
                                bottom: 10.0, right: 15, left: 15),
                            child: Text(
                              'This will not delete any photos or videos, just the tag itself.',
                              textAlign: TextAlign.center,
                              style: kTaglineText,
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: kGreyLight, width: 1),
                                bottom: BorderSide(color: kGreyLight, width: 1),
                              ),
                            ),
                            child: GestureDetector(
                              onTap: () {
                                TagService.instance.deleteTag(deleteTagLocal);
                                StoreService.instance.remove('deleteTagLocal');
                              },
                              child: const Padding(
                                padding: EdgeInsets.only(top: 10, bottom: 10.0),
                                child: Text(
                                  'Delete',
                                  textAlign: TextAlign.center,
                                  style: kGridDeleteElement,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: GestureDetector(
                              onTap: () {
                                StoreService.instance.remove('deleteTagLocal');
                              },
                              child: const Padding(
                                padding: EdgeInsets.only(top: 10.0),
                                child: Text(
                                  'Cancel',
                                  textAlign: TextAlign.center,
                                  style: kGridTagListElement,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )),
            // Delete modal
            Visibility(
                visible: currentlyDeletingModal,
                child: Center(
                  child: Container(
                    height: 225,
                    width: 225,
                    decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius:
                            const BorderRadius.all(Radius.circular(20)),
                        border: Border.all(color: kGreyLight, width: .5)),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 15.0),
                      child: Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(
                                bottom: 20.0, right: 15, left: 15),
                            child: Text(
                              'Delete from your phone?',
                              textAlign: TextAlign.center,
                              style: kDeleteModalTitle,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(
                                bottom: 10.0, right: 15, left: 15),
                            child: Text(
                              'This action cannot be undone. This will permanently delete these photos and videos from your device.',
                              textAlign: TextAlign.center,
                              style: kGridBottomRowText,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 10.0),
                            child: Text(
                              'Are you sure?',
                              textAlign: TextAlign.center,
                              style: kGridBottomRowText,
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: kGreyLight, width: 1),
                                bottom: BorderSide(color: kGreyLight, width: 1),
                              ),
                            ),
                            child: GestureDetector(
                              onTap: () {
                                var pivsToDelete = StoreService.instance
                                    .get('currentlyDeletingPivsLocal');
                                UploadService.instance
                                    .deleteLocalPivs(pivsToDelete);
                                StoreService.instance
                                    .remove('currentlyDeletingLocal');
                                StoreService.instance
                                    .remove('currentlyDeletingPivsLocal');
                                StoreService.instance
                                    .remove('currentlyDeletingModalLocal');
                              },
                              child: const Padding(
                                padding: EdgeInsets.only(top: 10, bottom: 10.0),
                                child: Text(
                                  'Delete',
                                  textAlign: TextAlign.center,
                                  style: kDeleteModalTitle,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: GestureDetector(
                              onTap: () {
                                StoreService.instance
                                    .remove('currentlyDeletingLocal');
                                StoreService.instance
                                    .remove('currentlyDeletingPivsLocal');
                                StoreService.instance
                                    .remove('currentlyDeletingModalLocal');
                              },
                              child: const Padding(
                                padding: EdgeInsets.only(top: 10.0),
                                child: Text(
                                  'Cancel',
                                  textAlign: TextAlign.center,
                                  style: kGridTagListElement,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ))
          ],
        );
      },
    );
  }
}

class Grid extends StatefulWidget {
  const Grid({
    Key? key,
    required this.localPagesIndex,
  }) : super(key: key);

  final dynamic localPagesIndex;

  @override
  State<Grid> createState() => _GridState();
}

class _GridState extends State<Grid> {
  dynamic cancelListener;
  bool localPivsLoaded = UploadService.instance.localPivsLoaded;
  dynamic page = '';

  @override
  void initState() {
    super.initState();
    loadPivs();
    cancelListener = StoreService.instance
        .listen(['localPage:' + widget.localPagesIndex.toString ()],
            (v1) {
      setState(() {
        page = v1;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    cancelListener();
  }

  loadPivs() async {
    if (!localPivsLoaded) {
      while (UploadService.instance.localPivsLoaded == false) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }
    localPivsLoaded = true;
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: localPivsLoaded && page != '',
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20.0, top: 180),
        child: page['pivs'].length == 0
            ? Text('You\'re all done!')
            : SizedBox.expand(
                child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: GridView.builder(
                        reverse: true,
                        shrinkWrap: true,
                        cacheExtent: 50,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 1,
                          crossAxisSpacing: 1,
                        ),
                        itemCount: page['pivs'].length,
                        itemBuilder: (BuildContext context, index) {
                          return LocalGridItem(page['pivs'][index]);
                        })),
              ),
      ),
      replacement: Center(
        child: Container(
            color: Colors.grey[50],
            child: const CircularProgressIndicator(
              color: kAltoBlue,
            )),
      ),
    );
  }
}

class TopRow extends StatefulWidget {
  const TopRow({
    Key? key,
    required this.localPagesIndex,
  }) : super(key: key);

  final dynamic localPagesIndex;

  @override
  State<TopRow> createState() => _TopRowState();
}

class _TopRowState extends State<TopRow> {
  dynamic cancelListener;

  String currentlyTagging = '';
  dynamic taggedPivCount = '';
  dynamic displayMode = '';
  dynamic prev = '';
  dynamic page = '';
  dynamic next = '';

  @override
  void initState() {
    PhotoManager.requestPermissionExtend();
    super.initState();
    cancelListener = StoreService.instance
        .listen(['currentlyTaggingLocal', 'taggedPivCountLocal', 'displayMode', 'localPage:' + (widget.localPagesIndex - 1).toString (), 'localPage:' + widget.localPagesIndex.toString (), 'localPage:' + (widget.localPagesIndex + 1).toString ()],
            (v1, v2, v3, v4, v5, v6) {
      setState(() {
        currentlyTagging = v1;
        taggedPivCount = v2;
        displayMode = v3;
        prev = v4;
        page = v5;
        next = v6;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    cancelListener();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: Colors.white,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20),
              child: Column(
                children: [
                  Padding(
                      padding: const EdgeInsets.only(
                        top: 10,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width:
                                SizeService.instance.screenWidth(context) * .7,
                            child: LinearProgressIndicator(
                              value: page['total'] == 0
                                  ? 1
                                  : max(
                                      (page['total'] -
                                              page['left']) /
                                          page['total'],
                                      0.1),
                              color: kAltoBlue,
                              backgroundColor: Colors.white,
                            ),
                          ),
                          SizedBox(
                            width:
                                SizeService.instance.screenWidth(context) * .13,
                          ),
                          Visibility(
                            visible: displayMode == 'all',
                            child: Padding(
                              padding: const EdgeInsets.only(right: 2),
                              child: GestureDetector(
                                onTap: () {
                                  StoreService.instance.set('displayMode', '');
                                },
                                child: const Icon(
                                  kEyeIcon,
                                  color: kGreyDarker,
                                  size: 20,
                                ),
                              ),
                            ),
                            replacement: Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: GestureDetector(
                                onTap: () {
                                  StoreService.instance
                                      .set('displayMode', 'all');
                                },
                                child: const Icon(
                                  kSlashedEyeIcon,
                                  color: kGreyDarker,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )),
                  Padding(
                      padding: EdgeInsets.only(top: 10.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              page['left'].toString() + ' left',
                              style: kLookingAtText,
                            ),
                          ),
                        ],
                      )),
                  Padding(
                    padding: EdgeInsets.only(top: 15.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                              next != '' ? next['title'] : '',
                              textAlign: TextAlign.center,
                              style: kLeftAndRightPhoneGridTitle,
                              key: Key('left-title' + now().toString())),
                        ),
                        Expanded(
                            child: Text(page['title'],
                                style: kCenterPhoneGridTitle,
                                textAlign: TextAlign.center,
                                key: Key('center-title' + now().toString()))),
                        Expanded(
                            child: Text(
                                prev != '' ? prev['title'] : '',
                                textAlign: TextAlign.center,
                                style: kLeftAndRightPhoneGridTitle,
                                key: Key('right-title' + now().toString()))),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
        currentlyTagging != ''
            ? Container(
                height: 60,
                width: double.infinity,
                decoration: const BoxDecoration(
                  border:
                      Border(top: BorderSide(width: 1, color: kGreyLighter)),
                  color: Colors.white,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 12),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(right: 8.0),
                        child: Text(
                          'Now tagging with',
                          style: kLookingAtText,
                        ),
                      ),
                      GridTagElement(
                        gridTagElementIcon: kTagIcon,
                        iconColor: tagColor(currentlyTagging),
                        gridTagName: currentlyTagging,
                      ),
                      Expanded(
                        child: Text(
                          taggedPivCount.toString(),
                          textAlign: TextAlign.right,
                          style: kOrganizedAmountOfPivs,
                        ),
                      )
                    ],
                  ),
                ),
              )
            : Container()
      ],
    );
  }
}
