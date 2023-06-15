import 'dart:core';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tagaway/services/sizeService.dart';
import 'package:tagaway/services/storeService.dart';
import 'package:tagaway/services/tagService.dart';
import 'package:tagaway/ui_elements/constants.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

class SnackBarGlobal {
  SnackBarGlobal._();

  static buildSnackBar(
      BuildContext context, String message, String backgroundColorSnackBar) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: kSnackBarText,
        ),
        backgroundColor: Color(backgroundColorSnackBar == 'green'
            ? 0xFF04E762
            : backgroundColorSnackBar == 'red'
                ? 0xFFD33E43
                : 0xFFffff00),
        //  var colors = {green: '#04E762', red: '#D33E43', yellow: '#ffff00'};
      ),
    );
  }
}

class SixSecondSnackBar {
  SixSecondSnackBar._();

  static buildSnackBar(
      BuildContext context, String message, String backgroundColorSnackBar) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 6),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: kSnackBarText,
        ),
        backgroundColor: Color(backgroundColorSnackBar == 'green'
            ? 0xFF04E762
            : backgroundColorSnackBar == 'red'
                ? 0xFFD33E43
                : 0xFFffff00),
        //  var colors = {green: '#04E762', red: '#D33E43', yellow: '#ffff00'};
      ),
    );
  }
}

class WhiteSnackBar {
  WhiteSnackBar._();

  static buildSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: kWhiteSnackBarText,
        ),
        backgroundColor: Colors.white,
        duration: const Duration(seconds: 5),
        margin: const EdgeInsets.only(bottom: 50),
        padding: const EdgeInsets.all(20),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
    );
  }
}

class RoundedButton extends StatelessWidget {
  const RoundedButton(
      {Key? key,
      required this.title,
      required this.colour,
      required this.onPressed})
      : super(key: key);

  final Color colour;
  final String title;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(title, style: kButtonText),
        style: ElevatedButton.styleFrom(
            backgroundColor: colour,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
            minimumSize: const Size(200, 42)),
      ),
    );
  }
}

class WhiteRoundedButton extends StatelessWidget {
  const WhiteRoundedButton(
      {Key? key, required this.title, required this.onPressed})
      : super(key: key);

  final String title;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(title, style: kWhiteButtonText),
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
            minimumSize: const Size(200, 42)),
      ),
    );
  }
}

class HomeCard extends StatelessWidget {
  const HomeCard({
    Key? key,
    required this.color,
    required this.title,
  }) : super(key: key);

  final Color color;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Container(
        height: 140,
        width: 1000,
        padding: const EdgeInsets.only(top: 12),
        decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.all(Radius.circular(20))),
        child: Padding(
          padding: const EdgeInsets.only(top: 80, left: 20),
          child: Text(
            title,
            style: kHomeTagBoxText,
          ),
        ),
      ),
    );
  }
}

class TagListElement extends StatelessWidget {
  const TagListElement({
    Key? key,
    required this.tagColor,
    required this.tagName,
    required this.onTap,
  }) : super(key: key);

  final Color tagColor;
  final String tagName;
  final Function onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap(),
      child: Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Container(
          height: 70,
          decoration: const BoxDecoration(
              color: kGreyLighter,
              borderRadius: BorderRadius.all(Radius.circular(10))),
          child: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Row(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: FaIcon(
                    kTagIcon,
                    color: tagColor,
                  ),
                ),
                Container(
                  constraints: BoxConstraints(
                    maxWidth: SizeService.instance.screenWidth(context) * .8,
                  ),
                  child: Text(
                    tagName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: kTagListElementText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EditTagListElement extends StatelessWidget {
  const EditTagListElement({
    Key? key,
    required this.tagColor,
    required this.tagName,
    required this.onTapOnRedCircle,
    required this.onTagElementVerticalDragDown,
  }) : super(key: key);

  final Color tagColor;
  final String tagName;
  final Function onTapOnRedCircle;
  final Function onTagElementVerticalDragDown;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        children: [
          GestureDetector(
            onTap: onTapOnRedCircle(),
            child: Container(
              child: const Icon(
                FontAwesomeIcons.circleMinus,
                color: kAltoRed,
              ),
              color: Colors.transparent,
              margin: const EdgeInsets.only(left: 10, right: 12),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onVerticalDragDown: onTagElementVerticalDragDown(),
              child: Container(
                height: 70,
                decoration: const BoxDecoration(
                    color: kGreyLighter,
                    borderRadius: BorderRadius.all(Radius.circular(10))),
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Row(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: FaIcon(
                          kTagIcon,
                          color: tagColor,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          tagName,
                          style: kTagListElementText,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 12, right: 12.0),
                        // child: FaIcon(
                        //   FontAwesomeIcons.bars,
                        //   color: kGrey,
                        // ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GridTagElement extends StatelessWidget {
  const GridTagElement({
    Key? key,
    required this.gridTagElementIcon,
    required this.iconColor,
    required this.gridTagName,
  }) : super(key: key);

  final IconData gridTagElementIcon;
  final Color iconColor;
  final String gridTagName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Container(
        height: 40,
        padding: const EdgeInsets.only(left: 12, right: 12),
        decoration: const BoxDecoration(
            color: kGreyLighter,
            borderRadius: BorderRadius.all(Radius.circular(10))),
        child: Row(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: FaIcon(
                gridTagElementIcon,
                color: iconColor,
                size: 20,
              ),
            ),
            Container(
              constraints: BoxConstraints(
                maxWidth: SizeService.instance
                    .gridTagElementMaxWidthCalculator(context),
              ),
              child: Text(gridTagName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: kGridTagListElement),
            ),
          ],
        ),
      ),
    );
  }
}

class GridTagUploadedQueryElement extends StatelessWidget {
  const GridTagUploadedQueryElement({
    Key? key,
    required this.gridTagElementIcon,
    required this.iconColor,
    required this.gridTagName,
  }) : super(key: key);

  final IconData gridTagElementIcon;
  final Color iconColor;
  final String gridTagName;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacementNamed(context, 'querySelector');
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: Container(
          height: 40,
          padding: const EdgeInsets.only(left: 12, right: 12),
          decoration: const BoxDecoration(
              color: kGreyLighter,
              borderRadius: BorderRadius.all(Radius.circular(10))),
          child: Row(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: FaIcon(
                  gridTagElementIcon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              Container(
                constraints: BoxConstraints(
                  maxWidth: SizeService.instance
                      .gridTagUploadedQueryElementMaxWidthCalculator(context),
                ),
                child: Text(gridTagName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: kGridTagListElement),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GridSeeMoreElement extends StatefulWidget {
  const GridSeeMoreElement({Key? key}) : super(key: key);

  @override
  State<GridSeeMoreElement> createState() => _GridSeeMoreElementState();
}

class _GridSeeMoreElementState extends State<GridSeeMoreElement> {
  dynamic cancelListener;

  dynamic queryTags = [];

  @override
  void initState() {
    super.initState();
    cancelListener = StoreService.instance.listen([
      'queryTags',
    ], (v1) {
      setState(() {
        if (v1 != '') queryTags = v1;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    cancelListener();
  }

  Function shorten =
      (tag) => tag.length < 15 ? tag : tag.substring(0, 15) + '...';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet<void>(
            context: context,
            builder: (BuildContext context) {
              return Container(
                  padding: const EdgeInsets.only(left: 12, right: 12),
                  color: Colors.white,
                  height: 600,
                  child: ListView(
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    children: [
                      const Icon(
                        kMinusIcon,
                        color: kGreyDarker,
                        size: 30,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: const [
                            Text(
                              'You’re looking at',
                              style: kLookingAtText,
                            ),
                          ],
                        ),
                      ),
                      GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: queryTags.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 4,
                          ),
                          itemBuilder: (BuildContext context, index) {
                            var tag = queryTags[index];
                            if (tag == 'u::')
                              return GridTagElement(
                                gridTagElementIcon: kTagIcon,
                                iconColor: kGrey,
                                gridTagName: 'Untagged',
                              );
                            if (tag == 't::')
                              return GridTagElement(
                                gridTagElementIcon: kBoxArchiveIcon,
                                iconColor: kGrey,
                                gridTagName: 'To Organize',
                              );
                            if (tag == 'o::')
                              return GridTagElement(
                                gridTagElementIcon: kCircleCheckIcon,
                                iconColor: kAltoOrganized,
                                gridTagName: 'Organized',
                              );
                            // DATE TAG
                            if (RegExp('^d::M').hasMatch(tag))
                              return GridTagElement(
                                  gridTagElementIcon: kClockIcon,
                                  iconColor: kGreyDarker,
                                  gridTagName: [
                                    'Jan',
                                    'Feb',
                                    'Mar',
                                    'Apr',
                                    'May',
                                    'Jun',
                                    'Jul',
                                    'Aug',
                                    'Sep',
                                    'Oct',
                                    'Nov',
                                    'Dec'
                                  ][int.parse(tag.substring(4)) - 1]);
                            if (RegExp('^d::').hasMatch(tag))
                              return GridTagElement(
                                  gridTagElementIcon: kClockIcon,
                                  iconColor: kGreyDarker,
                                  gridTagName: tag.substring(3));
                            // GEO TAG
                            if (RegExp('^g::').hasMatch(tag))
                              return GridTagElement(
                                  gridTagElementIcon: kLocationDotIcon,
                                  iconColor: kGreyDarker,
                                  gridTagName: tag.substring(3));
                            // NORMAL TAG
                            return GridTagElement(
                                gridTagElementIcon: kTagIcon,
                                iconColor: tagColor(tag),
                                gridTagName: shorten(tag));
                          })
                    ],
                  ));
            });
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: Container(
          height: 40,
          padding: const EdgeInsets.only(left: 12, right: 12),
          decoration: const BoxDecoration(
              color: kGreyLighter,
              borderRadius: BorderRadius.all(Radius.circular(10))),
          child: const Center(
            child: FaIcon(
              kEllipsisIcon,
              color: kGreyDarker,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class UserMenuElementTransparent extends StatelessWidget {
  const UserMenuElementTransparent({
    Key? key,
    required this.textOnElement,
  }) : super(key: key);

  final String textOnElement;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, right: 20, top: 5),
      child: Container(
        height: 50,
        decoration: const BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        child: Center(
            child: Text(
          textOnElement,
          style: kPlainTextBold,
        )),
      ),
    );
  }
}

class UserMenuElementLightGrey extends StatelessWidget {
  const UserMenuElementLightGrey({
    Key? key,
    required this.onTap,
    required this.textOnElement,
  }) : super(key: key);

  final VoidCallback onTap;
  final String textOnElement;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, right: 20, top: 5),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 50,
          decoration: const BoxDecoration(
            color: kGreyLight,
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          child: Center(
              child: Text(
            textOnElement,
            style: kPlainText,
          )),
        ),
      ),
    );
  }
}

class UserMenuElementDarkGrey extends StatelessWidget {
  const UserMenuElementDarkGrey({
    Key? key,
    required this.onTap,
    required this.textOnElement,
  }) : super(key: key);

  final Function onTap;
  final String textOnElement;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, right: 20, top: 5),
      child: GestureDetector(
        onTap: onTap(),
        child: Container(
          height: 50,
          decoration: const BoxDecoration(
            color: kGreyDarker,
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          child: Center(
              child: Text(textOnElement,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 16,
                    color: Colors.white,
                  ))),
        ),
      ),
    );
  }
}

class GridMonthElement extends StatelessWidget {
  const GridMonthElement(
      {Key? key,
      required this.roundedIcon,
      required this.roundedIconColor,
      required this.month,
      required this.whiteOrAltoBlueDashIcon,
      required this.onTap})
      : super(key: key);

  final IconData roundedIcon;
  final Color roundedIconColor;
  final String month;
  final Color whiteOrAltoBlueDashIcon;
  final dynamic onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            FaIcon(
              roundedIcon,
              color: roundedIconColor,
              size: 12,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(month, style: kHorizontalMonth),
            ),
            FaIcon(
              kMinusIcon,
              color: whiteOrAltoBlueDashIcon,
            )
          ],
        ));
  }
}

class QuerySelectionTagElement extends StatelessWidget {
  const QuerySelectionTagElement({
    Key? key,
    required this.elementColor,
    required this.icon,
    required this.iconColor,
    required this.tagTitle,
    required this.onTap,
  }) : super(key: key);

  final VoidCallback onTap;
  final Color elementColor;
  final IconData icon;
  final Color iconColor;
  final String tagTitle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
            color: elementColor,
            borderRadius: const BorderRadius.all(Radius.circular(10))),
        child: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Row(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(
                    right: SizeService.instance.screenWidth(context) < 380
                        ? 8
                        : 12.0),
                child: FaIcon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              Text(
                tagTitle,
                style: kLookingAtText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  const VideoPlayerWidget({Key? key, required this.pivId}) : super(key: key);
  final String pivId;

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool initialized = false;

  @override
  void initState() {
    _initVideo();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  _initVideo() async {
    _controller = VideoPlayerController.network(
      (kTagawayVideoURL) + (widget.pivId),
      httpHeaders: {
        'cookie': StoreService.instance.get('cookie'),
        'Range': 'bytes=0-',
      },
    );
    // Play the video again when it ends
    _controller.setLooping(true);
    // initialize the controller and notify UI when done
    _controller.initialize().then((_) => setState(() {
          initialized = true;
          _controller.play();
        }));
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? Stack(
            children: [
              Container(
                alignment: Alignment.topCenter,
                decoration: const BoxDecoration(
                  color: kGreyDarkest,
                ),
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              ),
              Align(
                alignment: const Alignment(0.8, .7),
                child: FloatingActionButton(
                  backgroundColor: kAltoBlue,
                  onPressed: () {
                    // Wrap the play or pause in a call to `setState`. This ensures the
                    // correct icon is shown.
                    setState(() {
                      // If the video is playing, pause it.
                      if (_controller.value.isPlaying) {
                        _controller.pause();
                      } else {
                        // If the video is paused, play it.
                        _controller.play();
                      }
                    });
                  },
                  // Display the correct icon depending on the state of the player.
                  child: Icon(
                    _controller.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                  ),
                ),
              ),
            ],
          )
        : const Center(
            child: CircularProgressIndicator(
            backgroundColor: kGreyDarkest,
            color: kAltoBlue,
          ));
  }
}

class VideoPending extends StatelessWidget {
  const VideoPending({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          left: 12.0,
          right: 12,
          bottom: SizeService.instance.screenHeight(context) * .1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Image.asset(
              'images/tag blue with white - 400x400.png',
              scale: 4,
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: Text(
              'Your video is currently being converted in our servers.',
              textAlign: TextAlign.center,
              style: kBigTitle,
            ),
          ),
          const Text(
            'Please try again in a few seconds.',
            textAlign: TextAlign.center,
            style: kPlainText,
          ),
        ],
      ),
    );
  }
}

class VideoError extends StatelessWidget {
  const VideoError({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          left: 12.0,
          right: 12,
          bottom: SizeService.instance.screenHeight(context) * .1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Image.asset(
              'images/tag blue with white - 400x400.png',
              scale: 4,
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: Text(
              'There\'s an error with your video.',
              textAlign: TextAlign.center,
              style: kBigTitle,
            ),
          ),
          const Text(
            'The problem is on our side. Sorry.',
            textAlign: TextAlign.center,
            style: kPlainText,
          ),
        ],
      ),
    );
  }
}

class GridItemSelection extends StatefulWidget {
  final String id;
  final String type;

  const GridItemSelection(this.id, this.type, {Key? key}) : super(key: key);

  @override
  State<GridItemSelection> createState() =>
      _GridItemSelectionState(this.id, this.type);
}

class _GridItemSelectionState extends State<GridItemSelection> {
  dynamic cancelListener;
  final String id;
  final String type;
  bool selected = false;

  _GridItemSelectionState(this.id, this.type);

  @override
  void initState() {
    super.initState();
    cancelListener = StoreService.instance.listen([
      (type == 'local' ? 'pivMap:' : 'orgMap:') + id,
      'tagMap:' + id,
      'currentlyTagging' + (type == 'local' ? 'Local' : 'Uploaded')
    ], (v1, v2, v3) {
      setState(() {
        if (v3 == '')
          selected = v1 != '';
        else
          selected = v2 != '';
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
    return Icon(
      selected ? kCircleCheckIcon : kSolidCircleIcon,
      color: selected ? kAltoOrganized : kGreyDarker,
      size: 15,
    );
  }
}

class AltocodeCommit extends StatelessWidget {
  const AltocodeCommit({
    Key? key,
  }) : super(key: key);

  launchAltocodeHome() async {
    if (!await launchUrl(Uri.parse(kAltoURL),
        mode: LaunchMode.externalApplication)) {
      throw "cannot launch url";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: TextButton(
        onPressed: () {
          launchAltocodeHome();
        },
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'altocode',
              style: kBlueAltocodeSubtitle,
            ),
            Text(
              'Commit to the future',
              style: kTaglineText,
            ),
          ],
        ),
      ),
    );
  }
}

class UploadingNumber extends StatefulWidget {
  const UploadingNumber({
    Key? key,
  }) : super(key: key);

  @override
  State<UploadingNumber> createState() => _UploadingNumberState();
}

class _UploadingNumberState extends State<UploadingNumber> {
  dynamic cancelListener;
  int numeroli = 0;

  @override
  void initState() {
    super.initState();
    cancelListener = StoreService.instance.listen(['uploadQueue'], (v1) {
      if (v1 != '') setState(() => numeroli = v1.length);
    });
  }

  @override
  void dispose() {
    super.dispose();
    cancelListener();
  }

  @override
  Widget build(BuildContext context) {
    if (numeroli == 0) return Text('');
    return Positioned(
      right: SizeService.instance.screenWidth(context) * .08,
      top: 2,
      child: Container(
        width: 25,
        height: 25,
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: kAltoBlue, width: 2)),
        child: Center(
          child: Text(
            numeroli.toString(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: kAltoBlue),
          ),
        ),
      ),
    );
  }
}

class DeleteButton extends StatelessWidget {
  const DeleteButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool visible = false;

    return Align(
      alignment: const Alignment(.92, .75),
      child: FloatingActionButton(
        heroTag: null,
        elevation: 10,
        key: const Key('delete'),
        onPressed: () {},
        backgroundColor: kAltoRed,
        child: const Icon(kTrashCanIcon),
      ),
    );
  }
}

class StartTaggingButton extends StatelessWidget {
  const StartTaggingButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, .92),
      child: FloatingActionButton.extended(
        heroTag: null,
        key: const Key('start tagging'),
        onPressed: () {},
        backgroundColor: kAltoBlue,
        label: const Text('Start tagging', style: kSelectAllButton),
      ),
    );
  }
}

class DoneTaggingButton extends StatelessWidget {
  const DoneTaggingButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
        alignment: const Alignment(0.8, .9),
        child: FloatingActionButton.extended(
          onPressed: () {
            StoreService.instance.set('swipedLocal', false);
            StoreService.instance.set('currentlyTaggingLocal', '');
            // We update the tag list in case we just created a new one.
            TagService.instance.getTags();
          },
          backgroundColor: kAltoBlue,
          label: const Text('Done', style: kSelectAllButton),
          icon: const Icon(Icons.done),
        ));
  }
}

class PicsWillBackupAsYouTagModal extends StatelessWidget {
  const PicsWillBackupAsYouTagModal({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
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
              padding:
                  EdgeInsets.only(top: 20.0, right: 15, left: 15, bottom: 10),
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
                      StoreService.instance.set('swipedLocal', true);
                      StoreService.instance.set('startTaggingModal', false);
                    }))
          ],
        ),
      ),
    ));
  }
}
