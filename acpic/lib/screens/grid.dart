// IMPORT FLUTTER PACKAGES
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:core';
import 'dart:async';
import 'package:photo_manager/photo_manager.dart';
import 'dart:io';
import 'dart:isolate';
// IMPORT UI ELEMENTS
import 'package:acpic/ui_elements/cupertino_elements.dart';
import 'package:acpic/ui_elements/android_elements.dart';
import 'package:acpic/ui_elements/constants.dart';
import 'package:acpic/ui_elements/material_elements.dart';
//IMPORT SCREENS
import 'grid_item.dart';
//IMPORT SERVICES
import 'package:acpic/services/local_vars_shared_prefsService.dart';
import 'package:acpic/services/deviceInfoService.dart';
import 'package:acpic/services/uploadService.dart';

class ProviderController extends ChangeNotifier {
  List<AssetEntity> selectedItems;
  List<AssetEntity> uploadList;

  int uploadProgress;
  void uploadProgressFunction(int newValue) {
    uploadProgress = newValue;
    notifyListeners();
  }

  Object redrawObject = Object();
  redraw() {
    redrawObject = Object();
  }

  bool all = false;
  void selectAllTapped(bool newValue) {
    all = newValue;
    notifyListeners();
  }

  bool isSelectionInProcess = false;
  void selectionInProcess(bool newValue) {
    isSelectionInProcess = newValue;
    notifyListeners();
  }

  bool isUploadingInProcess = false;
  void showUploadingProcess(bool newValue) {
    isUploadingInProcess = newValue;
    notifyListeners();
  }

  bool isUploadingPaused = false;
  void uploadingPausePlay(bool newValue) {
    isUploadingPaused = newValue;
    notifyListeners();
  }
}

class GridPage extends StatefulWidget {
  static const String id = 'grid_screen';
  @override
  _GridPageState createState() => _GridPageState();
}

class _GridPageState extends State<GridPage> {
  final selectedListLengthController = StreamController<int>.broadcast();

  @override
  void dispose() {
    selectedListLengthController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    return ChangeNotifierProvider<ProviderController>(
      create: (_) => ProviderController(),
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Grid(
                selectedListLengthStreamController:
                    selectedListLengthController,
              ),
              TopRow(),
              BottomRow(
                  selectedListLengthStreamController:
                      selectedListLengthController),
            ],
          ),
        ),
      ),
    );
  }
}

// Grid
class Grid extends StatefulWidget {
  final StreamController<int> selectedListLengthStreamController;

  Grid({@required this.selectedListLengthStreamController});

  @override
  _GridState createState() => _GridState();
}

class Item {
  Item({@required this.imgUrl, @required this.position});
  String imgUrl;
  int position;
}

class _GridState extends State<Grid> {
  List<AssetEntity> itemList;
  List<AssetEntity> selectedList;

  @override
  void initState() {
    loadList();
    super.initState();
  }

  loadList() {
    itemList = [];
    selectedList = [];
    _fetchAssets();
  }

  _fetchAssets() async {
    FilterOptionGroup makeOption() {
      // final option = FilterOption();
      return FilterOptionGroup()
        ..addOrderOption(
            OrderOption(type: OrderOptionType.createDate, asc: false));
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

  feedSelectedListProvider() {
    Provider.of<ProviderController>(context, listen: false).selectedItems =
        List.from(selectedList);
  }

  selectedListStreamSink() {
    widget.selectedListLengthStreamController.sink.add(selectedList.length);
    feedSelectedListProvider();
  }

  selectAll() {
    if (Provider.of<ProviderController>(context, listen: false).all == true) {
      selectedList = List.from(itemList);
      selectedListStreamSink();
    } else if (Provider.of<ProviderController>(context, listen: false)
            .isSelectionInProcess ==
        false) {
      selectedList.clear();
      selectedListStreamSink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 50.0),
      child: SizedBox.expand(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Selector<ProviderController, Object>(
            selector: (context, providerController) =>
                (providerController.redrawObject),
            builder: (context, providerData, child) {
              return GridView.builder(
                  reverse: true,
                  shrinkWrap: true,
                  cacheExtent: 50,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 5,
                    crossAxisSpacing: 5,
                  ),
                  itemCount: itemList.length,
                  key: ValueKey<Object>(providerData),
                  itemBuilder: (BuildContext context, index) {
                    selectAll();
                    return GridItem(
                      item: itemList[index],
                      isSelected: (bool value) {
                        if (value) {
                          selectedList.add(itemList[index]);
                          selectedListStreamSink();
                        } else {
                          selectedList.remove(itemList[index]);
                          selectedListStreamSink();
                        }
                        selectedList.length > 0
                            ? Provider.of<ProviderController>(context,
                                    listen: false)
                                .selectionInProcess(true)
                            : Provider.of<ProviderController>(context,
                                    listen: false)
                                .selectionInProcess(false);
                        // print("$index : $value");
                      },
                      key: Key(itemList[index].toString()),
                    );
                  });
            },
          ),
        ),
      ),
    );
  }
}

//Top Row
class TopRow extends StatefulWidget {
  @override
  _TopRowState createState() => _TopRowState();
}

class _TopRowState extends State<TopRow> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, right: 10),
      child: Visibility(
        visible:
            !(Provider.of<ProviderController>(context).isUploadingInProcess),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Visibility(
              visible: !(Provider.of<ProviderController>(context)
                  .isSelectionInProcess),
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    color: kAltoBlue,
                  ),
                  child: Platform.isIOS ? CupertinoLogOut() : AndroidLogOut(),
                ),
              ),
              replacement: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: kAltoGrey,
                  minimumSize: Size(40, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  textStyle: kButtonText,
                ),
                onPressed: () {
                  Provider.of<ProviderController>(context, listen: false)
                      .selectAllTapped(false);
                  Provider.of<ProviderController>(context, listen: false)
                      .redraw();
                  Provider.of<ProviderController>(context, listen: false)
                      .selectionInProcess(false);
                },
                child: Text(
                  'Cancel',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TheTopLevelFunctionArguments {
  final BuildContext context;
  final int id;
  final String csrf;
  final String cookie;
  final List tags;
  final List<AssetEntity> list;
  final Isolate isolate;
  final SendPort sendPort;

  TheTopLevelFunctionArguments(this.context, this.id, this.csrf, this.cookie,
      this.tags, this.list, this.isolate, this.sendPort);
}

theTopLevelFunction(TheTopLevelFunctionArguments arguments) async {
  uploadOne() async {
    if (arguments.list.isEmpty) {
      UploadService.instance.uploadEnd(
          'complete', arguments.csrf, arguments.id, arguments.cookie);
      UploadService.instance.uiReset(arguments.context);
      arguments.isolate.kill();
      print('Made it to the end');
      return false;
    }
    if (arguments.list.last.width == 00 && arguments.list.last.height == 00) {
      UploadService.instance
          .uploadEnd('cancel', arguments.csrf, arguments.id, arguments.cookie);
      arguments.list.clear();
      return false;
    }
    var asset = arguments.list[0];
    print(asset.type);
    var piv = asset.file;
    arguments.list.removeAt(0);
    Provider.of<ProviderController>(arguments.context, listen: false)
        .uploadProgressFunction(
            Provider.of<ProviderController>(arguments.context, listen: false)
                    .selectedItems
                    .length -
                arguments.list.length);

    File image = await piv;
    var uri = Uri.parse('https://altocode.nl/picdev/piv');
    var request = http.MultipartRequest('POST', uri);
    try {
      request.headers['cookie'] = arguments.cookie;
      request.fields['id'] = arguments.id.toString();
      request.fields['csrf'] = arguments.csrf;
      request.fields['tags'] = arguments.tags.toString();
      request.fields['lastModified'] =
          asset.modifiedDateTime.millisecondsSinceEpoch.abs().toString();
      request.files.add(await http.MultipartFile.fromPath('piv', image.path));
      var response = await request.send();
      final respStr = await response.stream.bytesToString();
      print(respStr);
      print('DEBUG response ' + response.statusCode.toString() + ' ' + respStr);
      if (response.statusCode == 409 && respStr == '{"error":"capacity"}') {
        UploadService.instance.uploadError(
            arguments.csrf,
            {'code': response.statusCode, 'error': respStr},
            arguments.id,
            arguments.cookie);
        UploadService.instance.uiReset(arguments.context);
        SnackBarGlobal.buildSnackBar(
            arguments.context, 'You\'ve run out of space.', 'red');
        return false;
      } else if (response.statusCode >= 500) {
        UploadService.instance.uploadError(
            arguments.csrf,
            {'code': response.statusCode, 'error': respStr},
            arguments.id,
            arguments.cookie);
        UploadService.instance.uiReset(arguments.context);
        SnackBarGlobal.buildSnackBar(
            arguments.context, 'Something is wrong on our side. Sorry.', 'red');
        return false;
      }
    } on SocketException catch (_) {
      print('Socket Exception');
      Provider.of<ProviderController>(arguments.context, listen: false)
          .uploadingPausePlay(true);
      SnackBarGlobal.buildSnackBar(
          arguments.context, 'You\'re offline. Upload paused.', 'red');
      arguments.list.insert(0, asset);
      UploadService.instance.uploadOnlineChecker(
          arguments.context,
          arguments.id,
          arguments.csrf,
          arguments.cookie,
          arguments.tags,
          arguments.list);
      return false;
    } on Exception {
      print('Exception');
      Provider.of<ProviderController>(arguments.context, listen: false)
          .uploadingPausePlay(true);
      SnackBarGlobal.buildSnackBar(
          arguments.context, 'You\'re offline. Upload paused.', 'red');
      arguments.list.insert(0, asset);
      UploadService.instance.uploadOnlineChecker(
          arguments.context,
          arguments.id,
          arguments.csrf,
          arguments.cookie,
          arguments.tags,
          arguments.list);
      return false;
    }
    if (Platform.isIOS) {
      image.delete();
      PhotoManager.clearFileCache();
    } else {
      PhotoManager.clearFileCache();
    }
    return true;
  }

  Future.doWhile(uploadOne);
}

//Bottom Row
class BottomRow extends StatefulWidget {
  final StreamController<int> selectedListLengthStreamController;

  BottomRow({@required this.selectedListLengthStreamController});

  @override
  _BottomRowState createState() => _BottomRowState();
}

class _BottomRowState extends State<BottomRow> {
  String cookie;
  String csrf;
  String model;
  int id;
  List tags;
  List<AssetEntity> list;
  Isolate isolate;
  final ReceivePort _receivePort = ReceivePort();
  StreamSubscription _subscription;

  theFunction(BuildContext context, int id, String csrf, String cookie,
      List tags, List<AssetEntity> list) async {
    try {
      if (isolate != null) {
        isolate.kill();
      }
      isolate = await Isolate.spawn<TheTopLevelFunctionArguments>(
          theTopLevelFunction,
          TheTopLevelFunctionArguments(context, id, csrf, cookie, tags, list,
              isolate, _receivePort.sendPort));
    } on IsolateSpawnException catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    SharedPreferencesService.instance.getStringValue('cookie').then((value) {
      setState(() {
        cookie = value;
      });
      // print('cookie is $cookie');
    });
    SharedPreferencesService.instance.getStringValue('csrf').then((value) {
      setState(() {
        csrf = value;
      });
      // print('csrf is $csrf');
    });
    Platform.isIOS
        ? DeviceInfoService.instance.iOSInfo().then((value) {
            setState(() {
              model = value;
            });
          })
        : DeviceInfoService.instance.androidInfo().then((value) {
            setState(() {
              model = value;
            });
          });
    super.initState();
    _subscription = _receivePort.listen((message) {
      print('message $message');
    });
  }

  @override
  void dispose() {
    isolate.kill();
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(right: 10, left: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Visibility(
                visible: !(Provider.of<ProviderController>(context)
                    .isUploadingInProcess),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    primary: Colors.white,
                    onPrimary: kAltoBlue,
                    minimumSize: Size(40, 40),
                    side: BorderSide(width: 1, color: kAltoBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    textStyle: kSelectAllButton,
                  ),
                  onPressed: () {
                    Provider.of<ProviderController>(context, listen: false)
                        .selectAllTapped(true);
                    Provider.of<ProviderController>(context, listen: false)
                        .redraw();
                    Provider.of<ProviderController>(context, listen: false)
                        .selectionInProcess(true);
                  },
                  child: Row(
                    children: <Widget>[
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Image.asset(
                            'images/icon-guide--upload.png',
                            scale: 16,
                          ),
                          Positioned.fill(
                            top: -2,
                            right: -2,
                            child: Align(
                              alignment: Alignment.topRight,
                              child: Icon(
                                Icons.circle,
                                size: 10,
                                color: kAltoBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 1),
                        child: Text(
                          'Select all',
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Visibility(
                  visible: !(Provider.of<ProviderController>(context)
                      .isUploadingInProcess),
                  child: StreamBuilder(
                    stream: widget.selectedListLengthStreamController.stream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError)
                        return Text('There\'s been an error');
                      else if (snapshot.connectionState ==
                          ConnectionState.waiting)
                        return Text(
                          'Loading your files',
                          style: kGridBottomRowText,
                        );
                      return Text(
                          (snapshot.data) < 1
                              ? 'No files selected'
                              : (snapshot.data) == 1
                                  ? '${snapshot.data} file selected'
                                  : '${snapshot.data} files selected',
                          style: kGridBottomRowText);
                    },
                  ),
                  replacement: StreamBuilder(
                      stream: widget.selectedListLengthStreamController.stream,
                      builder: (context, snapshot) {
                        if (snapshot.hasError)
                          return Text('There\'s been an error');
                        else if (snapshot.connectionState ==
                            ConnectionState.waiting)
                          return Text(
                            'Loading your files',
                            style: kGridBottomRowText,
                          );
                        return Provider.of<ProviderController>(context)
                                    .isUploadingPaused ==
                                false
                            ? Row(
                                children: [
                                  Text('Uploading ', style: kGridBottomRowText),
                                  Text(
                                      Provider.of<ProviderController>(context,
                                                      listen: false)
                                                  .uploadProgress ==
                                              null
                                          ? '0 of '
                                          : '${Provider.of<ProviderController>(context, listen: false).uploadProgress} of ',
                                      style: kGridBottomRowText),
                                  Text('${snapshot.data} files...',
                                      style: kGridBottomRowText),
                                ],
                              )
                            : Text('Uploading paused. Check connection.',
                                style: kGridBottomRowText);
                      })),
              Visibility(
                visible: !(Provider.of<ProviderController>(context)
                    .isUploadingInProcess),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    primary: kAltoBlue,
                    minimumSize: Size(40, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    textStyle: kButtonText,
                  ),
                  onPressed: () {
                    //--------- UPLOAD PROCESSES STARTS ---------
                    // --- UPLOAD LIST BECOMES SELECTED ITEMS LIST ---
                    Provider.of<ProviderController>(context, listen: false)
                        .uploadList = List.from(Provider.of<ProviderController>(
                            context,
                            listen: false)
                        .selectedItems);
                    // --- CHECK THAT SELECTED ITEMS IS NOT EMPTY  ---
                    if (Provider.of<ProviderController>(context, listen: false)
                            .selectedItems
                            .length >
                        0) {
                      // --- SELECTED ITEMS BECOMES 'LIST' ---
                      list = Provider.of<ProviderController>(context,
                              listen: false)
                          .selectedItems;
                      // --- SNACK BAR ---
                      SnackBarWithDismiss.buildSnackBar(context,
                          'Your files will keep uploading as long as ac;pic is running in the background.');
                      // --- SWITCH UI TO UPLOADING VIEW ---
                      Provider.of<ProviderController>(context, listen: false)
                          .showUploadingProcess(true);
                      // --- UPLOAD START CALL ---
                      UploadService.instance
                          .uploadStart(
                              'start',
                              csrf,
                              [model],
                              cookie,
                              Provider.of<ProviderController>(context,
                                      listen: false)
                                  .uploadList
                                  .length)
                          .then((value) {
                        // --- CHECK IS NOT OFFLINE ---
                        if (value == 'offline') {
                          SnackBarGlobal.buildSnackBar(context,
                              'You\'re offline. Check your connection.', 'red');
                        }
                        // --- CHECK SERVER ERROR ---
                        else if (value == 'error') {
                          SnackBarGlobal.buildSnackBar(context,
                              'Something is wrong on our side. Sorry.', 'red');
                        }
                        // --- START UPLOAD ---
                        else {
                          id = int.parse(value);
                          print('id is $id');
                          tags = ['"' + model + '"'];
                          theFunction(context, id, csrf, cookie, tags, list);

                          // UploadService.instance.uploadMain(
                          //     context,
                          //     id,
                          //     csrf,
                          //     cookie,
                          //     ['"' + model + '"'],
                          //     Provider.of<ProviderController>(context,
                          //             listen: false)
                          //         .uploadList);
                        }
                      });
                    }
                  },
                  child: Text(
                    'Upload',
                  ),
                ),
                replacement: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    primary: kAltoGrey,
                    minimumSize: Size(40, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    textStyle: kButtonText,
                  ),
                  onPressed: () {
                    //----- CANCEL UPLOAD PROCESS -----
                    Provider.of<ProviderController>(context, listen: false)
                        .uploadList
                        .add(AssetEntity(
                            id: 00.toString(),
                            typeInt: 01,
                            width: 00,
                            height: 00));
                    isolate.kill();
                    UploadService.instance.uiCancelReset(context);
                  },
                  child: Text(
                    'Cancel',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//TODO 3: Check that upload works in the background
//TODO 4: Implement hash engine
//TODO 5: (Mono) when the upload is finished or cancelled (but pivs where uploaded) send email to user
