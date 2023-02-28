import 'package:flutter/material.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:photo_manager/photo_manager.dart';

import 'package:tagaway/ui_elements/constants.dart';
import 'package:tagaway/ui_elements/material_elements.dart';

import 'package:tagaway/services/storeService.dart';
import 'package:tagaway/services/tagService.dart';

import 'package:tagaway/views/localGridItemView.dart';

class LocalView extends StatefulWidget {
  static const String id = 'local_view';

  const LocalView({Key? key}) : super(key: key);

  @override
  State<LocalView> createState() => _LocalViewState();
}

class _LocalViewState extends State<LocalView> {
  dynamic cancelListener;
  final TextEditingController newTagName = TextEditingController();

  dynamic usertags = [];
  String currentlyTagging = '';
  bool swiped = false;
  dynamic newTag = '';

  @override
  void initState() {
    PhotoManager.requestPermissionExtend();
    super.initState();
    cancelListener = StoreService.instance.listen (['usertags', 'currentlyTagging', 'swiped', 'newTag'], (v1, v2, v3, v4) {
      if (v2 != '') TagService.instance.getTaggedPivs (v2);
      setState(() {
        if (v1 != '') usertags = v1;
        currentlyTagging = v2;
        if (v3 != '') swiped = v3;
        newTag = v4;
      });
    });
  }

  @override
  void dispose () {
     super.dispose ();
     cancelListener ();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Grid(),
        const TopRow(),
        Visibility(
            visible: currentlyTagging != '',
            child: Align(
                alignment: const Alignment(0.8, .9),
                child: FloatingActionButton.extended(
                  onPressed: () {
                    StoreService.instance.set('swiped', false, true);
                    StoreService.instance.set('currentlyTagging', '', true);
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
                    StoreService.instance.set('swiped', false, true);
                  if (state.extent > 0.7699)
                    StoreService.instance.set('swiped', true, true);
                  return true;
                },
                child: DraggableScrollableSheet(
                    snap: true,
                    initialChildSize: .07,
                    minChildSize: .07,
                    maxChildSize: .77,
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
                            padding: const EdgeInsets.only(left: 12, right: 12),
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
                                      padding:
                                          EdgeInsets.only(top: 8.0, bottom: 8),
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
                                      padding:
                                          EdgeInsets.only(top: 8.0, bottom: 8),
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
                                      padding:
                                          EdgeInsets.only(top: 8.0, bottom: 8),
                                      child: Text(
                                        'Choose a tag and select the pics & videos you want!',
                                        textAlign: TextAlign.center,
                                        style: kPlainTextBold,
                                      ),
                                    ),
                                  )),
                              for (var v in usertags)
                                TagListElement(
                                    tagColor: tagColor(v),
                                    tagName: v,
                                    onTap: () {
                                      // We need to wrap this in another function, otherwise it gets executed on view draw. Madness.
                                      return () {
                                        StoreService.instance
                                            .set('currentlyTagging', v, true);
                                      };
                                    })
                            ],
                          ),
                        ),
                      );
                    }),
              )),
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
                              StoreService.instance.set('newTag', '', true);
                              newTagName.clear();
                            },
                            child: Padding(
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
                              StoreService.instance.set('newTag', '', true);
                              StoreService.instance
                                  .set('currentlyTagging', text, true);
                              newTagName.clear();
                            },
                            child: Text(
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
                  StoreService.instance.set('newTag', true, true);
                },
                backgroundColor: kAltoBlue,
                label: const Text('Create tag', style: kSelectAllButton),
              ),
            )),
        // Center(
        //     child: Padding(
        //   padding: const EdgeInsets.only(left: 12, right: 12),
        //   child: Container(
        //     height: 180,
        //     width: double.infinity,
        //     decoration: const BoxDecoration(
        //       color: kAltoBlue,
        //       borderRadius: BorderRadius.all(Radius.circular(20)),
        //     ),
        //     child: Column(
        //       children: [
        //         const Padding(
        //           padding: EdgeInsets.only(
        //               top: 20.0, right: 15, left: 15, bottom: 10),
        //           child: Text(
        //             'Your pics will backup as you tag them',
        //             textAlign: TextAlign.center,
        //             style: kWhiteSubtitle,
        //           ),
        //         ),
        //         Center(
        //             child: WhiteRoundedButton(
        //                 title: 'Start tagging', onPressed: () {}))
        //       ],
        //     ),
        //   ),
        // ))
      ],
    );
  }
}

class Grid extends StatefulWidget {
  const Grid({Key? key}) : super(key: key);

  @override
  State<Grid> createState() => _GridState();
}

class _GridState extends State<Grid> {
  List<AssetEntity> itemList = [];

  @override
  void initState() {
    super.initState();
    fetchAssets ();
  }

  fetchAssets() async {
    FilterOptionGroup makeOption() {
      // final option = FilterOption();
      return FilterOptionGroup()
        ..addOrderOption(
            const OrderOption(type: OrderOptionType.createDate, asc: false));
    }

    final option = makeOption();
    // Set onlyAll to true, to fetch only the 'Recent' album
    // which contains all the photos/videos in the storage
    final albums = await PhotoManager.getAssetPathList(
        onlyAll: true, filterOption: option);
    final recentAlbum = albums.first;

    // Now that we got the album, fetch all the assets it contains
    final recentAssets = await recentAlbum.getAssetListRange(
      start: 0, // start at index 0
      end: 1000000, // end at a very big index (to get all the assets)
    );

    // Update the state and notify UI
    setState(() => itemList = recentAssets);
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
                itemCount: itemList.length,
                itemBuilder: (BuildContext context, index) {
                  return LocalGridItem(itemList[index]);
                })),
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

  @override
  void initState() {
    PhotoManager.requestPermissionExtend();
    super.initState();
    cancelListener = StoreService.instance.listen (['currentlyTagging'], (v) {
      setState(() {
        currentlyTagging = v;
      });
    });
  }

  @override
  void dispose () {
     super.dispose ();
     cancelListener ();
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
                    children: const [
                      Expanded(
                        child: Align(
                          alignment: Alignment(0.29, .9),
                          child: Text(
                            '2022',
                            textAlign: TextAlign.center,
                            style: kLocalYear,
                          ),
                        ),
                      ),
                      Icon(
                        kSearchIcon,
                        color: Colors.white,
                        size: 25,
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 20.0),
                        child: Icon(
                          kSlidersIcon,
                          color: Colors.white,
                          size: 25,
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
                          children: const [
                            GridMonthElement(
                              roundedIcon: kSolidCircleIcon,
                              roundedIconColor: kGreyDarker,
                              month: 'Jul',
                              whiteOrAltoBlueDashIcon: Colors.white,
                            ),
                            GridMonthElement(
                              roundedIcon: kCircleCheckIcon,
                              roundedIconColor: kAltoOrganized,
                              month: 'Aug',
                              whiteOrAltoBlueDashIcon: Colors.white,
                            ),
                            GridMonthElement(
                              roundedIcon: kEmptyCircle,
                              roundedIconColor: kGreyDarker,
                              month: 'Sep',
                              whiteOrAltoBlueDashIcon: Colors.white,
                            ),
                            GridMonthElement(
                              roundedIcon: kCircleCheckIcon,
                              roundedIconColor: kAltoOrganized,
                              month: 'Oct',
                              whiteOrAltoBlueDashIcon: Colors.white,
                            ),
                            GridMonthElement(
                              roundedIcon: kSolidCircleIcon,
                              roundedIconColor: kGreyDarker,
                              month: 'Nov',
                              whiteOrAltoBlueDashIcon: Colors.white,
                            ),
                            GridMonthElement(
                              roundedIcon: FontAwesomeIcons.solidCircleCheck,
                              roundedIconColor: kAltoOrganized,
                              month: 'Dec',
                              whiteOrAltoBlueDashIcon: kAltoBlue,
                            ),
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
                      Padding(
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
                          '4,444',
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
