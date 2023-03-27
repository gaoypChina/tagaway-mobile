import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tagaway/services/storeService.dart';
import 'package:tagaway/services/tagService.dart';
import 'package:tagaway/ui_elements/constants.dart';
import 'package:tagaway/ui_elements/material_elements.dart';
import 'package:tagaway/views/uploadedGridItemView.dart';

class UploadedView extends StatefulWidget {
  static const String id = 'uploaded';

  const UploadedView({Key? key}) : super(key: key);

  @override
  State<UploadedView> createState() => _UploadedViewState();
}

class _UploadedViewState extends State<UploadedView> {
  dynamic cancelListener;
  final TextEditingController newTagName = TextEditingController();

  dynamic usertags = [];
  String currentlyTagging = '';
  bool swiped = false;
  dynamic newTag = '';
  dynamic startTaggingModal = '';

  // When clicking on one of the buttons of this widget, we want the ScrollableDraggableSheet to be opened. Unfortunately, the methods provided in the controller for it (`animate` and `jumpTo`) change the scroll position of the sheet, but not its height.
  // For this reason, we need to set the `initialChildSize` directly. This is not a clean solution, and it lacks an animation. But it's the best we've come up with so far.
  // For more info, refer to https://github.com/flutter/flutter/issues/45009
  double initialChildSize = 0.07;

  @override
  void initState() {
    super.initState();
    cancelListener = StoreService.instance.listen([
      'usertags',
      'currentlyTagging',
      'swiped',
      'newTag',
      'startTaggingModal'
    ], (v1, v2, v3, v4, v5) {
      var currentView = StoreService.instance.get ('currentIndex');
      // Invoke the service only if local is not the current view
      if (v2 != '' && currentView != 1) TagService.instance.getUploadedTaggedPivs(v2);
      setState(() {
        if (v1 != '') usertags = v1;
        if (currentView != 1) {
           currentlyTagging = v2;
           if (v3 != '') swiped = v3;
           newTag = v4;
           startTaggingModal = v5;
           if (swiped == false && initialChildSize > 0.07) initialChildSize = 0.07;
           if (swiped == true && initialChildSize < 0.77) initialChildSize = 0.77;
        }
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
    return Stack(
      children: [
        const UploadGrid(),
        const TopRow(),
        Visibility(
            visible: currentlyTagging != '',
            child: Align(
                alignment: const Alignment(0.8, .9),
                child: FloatingActionButton.extended(
                  onPressed: () {
                    StoreService.instance.set('swiped', false);
                    StoreService.instance.set('currentlyTagging', '');
                    // We update the tag list in case we just created a new one.
                    TagService.instance.getTags();
                  },
                  backgroundColor: kAltoBlue,
                  label: const Text('Done', style: kSelectAllButton),
                  icon: const Icon(Icons.done),
                ))),
        Visibility(
            visible: currentlyTagging == '',
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox.expand(
                child: NotificationListener<DraggableScrollableNotification>(
                    onNotification: (state) {
                      if (state.extent < 0.0701)
                        StoreService.instance.set('swiped', false);
                      if (state.extent > 0.7699)
                        StoreService.instance.set('swiped', true);
                      StoreService.instance
                          .set('startTaggingModal', false);
                      return true;
                    },
                    child: DraggableScrollableSheet(
                        snap: true,
                        initialChildSize: initialChildSize,
                        minChildSize: 0.07,
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
                                      child: const Center(
                                        child: Padding(
                                          padding: EdgeInsets.only(top: 8.0),
                                          child: FaIcon(
                                            FontAwesomeIcons.anglesUp,
                                            color: kGrey,
                                            size: 16,
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
                                      child: const Center(
                                        child: Padding(
                                          padding: EdgeInsets.only(top: 8.0),
                                          child: FaIcon(
                                            FontAwesomeIcons.anglesDown,
                                            color: kGrey,
                                            size: 16,
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
                                  Visibility(
                                      visible: swiped,
                                      child: const Center(
                                        child: Padding(
                                          padding: EdgeInsets.only(
                                              top: 8.0, bottom: 8),
                                          child: Text(
                                            'Choose a tag and select the pics & videos you want!',
                                            textAlign: TextAlign.center,
                                            style: kPlainTextBold,
                                          ),
                                        ),
                                      )),
                                  ListView.builder(
                                      itemCount: usertags.length,
                                      padding: EdgeInsets.zero,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
                                      itemBuilder:
                                          (BuildContext context, int index) {
                                        var tag = usertags[index];
                                        return TagListElement(
                                          tagColor: tagColor(tag),
                                          tagName: tag,
                                          onTap: () {
                                            // We need to wrap this in another function, otherwise it gets executed on view draw. Madness.
                                            return () {
                                              StoreService.instance.set(
                                                  'currentlyTagging',
                                                  tag);
                                            };
                                          },
                                        );
                                      })
                                ],
                              ),
                            ),
                          );
                        })),
              ),
            )),
        Visibility(
            visible: newTag != '',
            child: Container(
              height: double.infinity,
              width: double.infinity,
              color: kAltoBlue.withOpacity(.8),
            )),
        Visibility(
            visible: newTag != '',
            child: Center(
                child: Padding(
              padding: const EdgeInsets.only(left: 12, right: 12),
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 20.0),
                      child: Text(
                        'Create a new tag',
                        style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: kAltoBlue),
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 12, right: 12, top: 20),
                      child: TextField(
                        controller: newTagName,
                        autofocus: true,
                        textAlign: TextAlign.center,
                        enableSuggestions: true,
                        decoration: const InputDecoration(
                          hintText: 'Insert the name of your new tag here…',
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 10.0, horizontal: 10.0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(25)),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 30.0, right: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: () {
                              StoreService.instance.set('newTag', '');
                              newTagName.clear();
                            },
                            child: const Padding(
                              padding: EdgeInsets.only(right: 30.0),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: kAltoBlue),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              var text = newTagName.text;
                              if (text == '') return;
                              StoreService.instance.set('newTag', '');
                              StoreService.instance
                                  .set('currentlyTagging', text);
                              newTagName.clear();
                            },
                            child: const Text(
                              'Create',
                              style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: kAltoBlue),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ))),
        Visibility(
            visible: newTag == '' && swiped == true && currentlyTagging == '',
            child: Align(
              alignment: const Alignment(0, .9),
              child: FloatingActionButton.extended(
                onPressed: () {
                  StoreService.instance.set('newTag', true);
                },
                backgroundColor: kAltoBlue,
                label: const Text('Create tag', style: kSelectAllButton),
              ),
            )),
      ],
    );
  }
}

class UploadGrid extends StatefulWidget {
  const UploadGrid({Key? key}) : super(key: key);

  @override
  State<UploadGrid> createState() => _UploadGridState();
}

class _UploadGridState extends State<UploadGrid> {
  dynamic cancelListener;
  dynamic cancelListener2;
  dynamic queryResult = {'pivs': [], 'total': 0};
  dynamic selectedList = [];

  @override
  void initState() {
    super.initState();
    if (StoreService.instance.get('queryTags') == '')
      StoreService.instance.set('queryTags', []);
    cancelListener = StoreService.instance.listen(['queryTags'], (v1) {
      if (v1 == '') v1 = [];
      TagService.instance.queryPivs(v1).then((value) {
        StoreService.instance.set('queryResult', value);
      });
    });
    cancelListener2 = StoreService.instance.listen([
      'queryResult',
    ], (v1) {
      if (v1 == '') return 0;
      if (v1['code'] == 403)
        return Navigator.pushReplacementNamed(context, 'distributor');
      // TODO: HANDLE NON-403, NON-200
      if (v1['code'] == 200)
        setState(() {
          queryResult = v1['body'];
        });
    });
  }

  @override
  void dispose() {
    super.dispose();
    cancelListener();
    cancelListener2();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 0.0),
      child: SizedBox.expand(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: GridView.builder(
              reverse: true,
              shrinkWrap: true,
              cacheExtent: 50,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 1,
                crossAxisSpacing: 1,
              ),
              itemCount: queryResult['pivs'].length,
              itemBuilder: (BuildContext context, index) {
                return UploadedGridItem(
                    item: queryResult['pivs'][index],
                    pivs: queryResult['pivs']);
              }),
        ),
      ),
    );
  }
}

class TopRow extends StatefulWidget {
  const TopRow({Key? key}) : super(key: key);

  @override
  State<TopRow> createState() => _TopRowState();
}

class _TopRowState extends State<TopRow> {
  dynamic cancelListener;
  String currentlyTagging = '';
  dynamic queryTags = [];
  dynamic queryResult = {'total': 0};
  dynamic taggedPivCount = '';

  @override
  void initState() {
    super.initState();
    cancelListener =
        StoreService.instance.listen(['queryTags', 'queryResult', 'currentlyTagging', 'taggedPivCount'], (v1, v2, v3, v4) {
      setState(() {
        if (v1 != '') queryTags = v1;
        if (v2 != '') queryResult = v2['body'];
        currentlyTagging = v3;
        taggedPivCount = v4;
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
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 12.0, right: 12),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Align(
                          alignment: Alignment(0.29, .9),
                          child: Text(
                            '2022',
                            textAlign: TextAlign.center,
                            style: kLocalYear,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacementNamed(context, 'searchTags');
                        },
                        child: const Icon(
                          kSearchIcon,
                          color: kGreyDarker,
                          size: 25,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 20.0),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushReplacementNamed(
                                context, 'querySelector');
                          },
                          child: Transform.rotate(
                            angle: 90 * -math.pi / 180.0,
                            child: const Icon(
                              kSlidersIcon,
                              color: kGreyDarker,
                              size: 25,
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: SizedBox(
                    height: 80,
                    child: ListView(
                      reverse: true,
                      scrollDirection: Axis.horizontal,
                      children: [
                        GridView.count(
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 1,
                          crossAxisSpacing: 0,
                          shrinkWrap: true,
                          scrollDirection: Axis.horizontal,
                          childAspectRatio: 1.11,
                          children: [
                            GridMonthElement(
                                roundedIcon: kSolidCircleIcon,
                                roundedIconColor: kGreyDarker,
                                month: 'Jul',
                                whiteOrAltoBlueDashIcon: Colors.white,
                                onTap: () {}),
                            GridMonthElement(
                                roundedIcon: kCircleCheckIcon,
                                roundedIconColor: kAltoOrganized,
                                month: 'Aug',
                                whiteOrAltoBlueDashIcon: Colors.white,
                                onTap: () {}),
                            GridMonthElement(
                                roundedIcon: kEmptyCircle,
                                roundedIconColor: kGreyDarker,
                                month: 'Sep',
                                whiteOrAltoBlueDashIcon: Colors.white,
                                onTap: () {}),
                            GridMonthElement(
                                roundedIcon: kCircleCheckIcon,
                                roundedIconColor: kAltoOrganized,
                                month: 'Oct',
                                whiteOrAltoBlueDashIcon: Colors.white,
                                onTap: () {}),
                            GridMonthElement(
                                roundedIcon: kSolidCircleIcon,
                                roundedIconColor: kGreyDarker,
                                month: 'Nov',
                                whiteOrAltoBlueDashIcon: Colors.white,
                                onTap: () {}),
                            GridMonthElement(
                                roundedIcon: FontAwesomeIcons.solidCircleCheck,
                                roundedIconColor: kAltoOrganized,
                                month: 'Dec',
                                whiteOrAltoBlueDashIcon: kAltoBlue,
                                onTap: () {}),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              ],
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
            : Container(),
        currentlyTagging == '' ?
        Container(
          height: 60,
          width: double.infinity,
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(width: 1, color: kGreyLighter)),
            color: Colors.white,
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 12, right: 12),
            child: Row(children: (() {
              List<Widget> output = [];
              queryTags.forEach((tag) {
                // Show first two tags only
                if (output.length > 2) return;
                // DATE TAG
                if (RegExp('^d::').hasMatch(tag))
                  return output.add(GridTagElement(
                      gridTagElementIcon: kClockIcon,
                      iconColor: kGreyDarker,
                      gridTagName: tag.slice(3)));
                // GEO TAG
                if (RegExp('^g::').hasMatch(tag))
                  return output.add(GridTagElement(
                      gridTagElementIcon: kLocationDotIcon,
                      iconColor: kGreyDarker,
                      gridTagName: tag.slice(3)));
                // NORMAL TAG (TODO: FIX STYLES)
                output.add(GridTagElement(
                    gridTagElementIcon: kLocationDotIcon,
                    iconColor: kGreyDarker,
                    gridTagName: tag));
              });
              if (queryTags.isEmpty) {
                output.add(Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: Text(
                    'You’re looking at',
                    style: kLookingAtText,
                  ),
                ));
                output.add(GridTagElement(
                    gridTagElementIcon: kCameraIcon,
                    iconColor: kGreyDarker,
                    gridTagName: 'Everything'));
              }
              if (queryTags.length > 2) output.add(GridSeeMoreElement());
              output.add(Expanded(
                child: Text(
                  queryResult['total'].toString(),
                  textAlign: TextAlign.right,
                  style: kUploadedAmountOfPivs,
                ),
              ));
              return output;
            })()),
          ),
        ) : Container (),
      ],
    );
  }
}
