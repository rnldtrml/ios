// import 'dart:async';
import 'dart:async';
// import 'dart:html';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_out_ios/application/config/constants.dart';
import 'package:in_out_ios/application/config/session.dart' as session;
import 'package:device_info/device_info.dart';
// import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:in_out_ios/application/helper/AudioPlay.dart';
import 'package:vibration/vibration.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_out_ios/application/libraries/mylibrary.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:qrscan/qrscan.dart' as scanner;
import 'package:permission_handler/permission_handler.dart';

class HomePage extends StatefulWidget{
  final String title ="";
  const HomePage ({Key? key, required title}) : super(key: key);
  @override
  _HomePageState createState() => _HomePageState();
  }

class _HomePageState extends State {
  Uint8List bytes = Uint8List(0);
  
  AudioPlay scanPlayer =  AudioPlay();
  AudioPlay errorScanPlayer =  AudioPlay();
  String _barcode = "";
  String _lattitude = "";
  String _longitude = "";
  int? type;
  

  // StreamSubscription<Positioned>? _positionStreamSubscription;

  MyLibrary mylibrary = MyLibrary();
  final _spServerUrl = TextEditingController();
  final _appServer = TextEditingController();
  int lastTap = DateTime.now().millisecondsSinceEpoch;
  int consecutiveTaps = 0;
  bool _isStart = false;

  @override
  void initState() {
    _longitude = "UNKNOWN";
    _lattitude = "UNKNOWN";
    super.initState();
    getLocation();
    _getDeviceDetails();
    _getAppSettings();
  }

  void getLocation() async {
    await Geolocator.checkPermission();
    await Geolocator.requestPermission();
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
    setState(() {
      _lattitude = position.latitude.toString();
      _longitude = position.longitude.toString();
    });
    // _positionStreamSubscription.pause();
  }

  // void _toggleListening() async {
  //   if (_positionStreamSubscription == null) {
  //     LocationOptions locationOptions = LocationOptions(accuracy: LocationAccuracy.medium);
  //     final Stream<Position> positionStream = Geolocator().getPositionStream(locationOptions);
  //     _positionStreamSubscription = positionStream.listen((Position position) => setState(() {
  //               this._lattitude = position.latitude.toString();
  //               this._longitude = position.longitude.toString();
  //               _isStart = true;
  //             }));
  //     _positionStreamSubscription.pause();
  //   }

  //   setState(() {
  //     if (_positionStreamSubscription.isPaused) {
  //       _positionStreamSubscription.resume();
  //     } else {
  //       _positionStreamSubscription.pause();
  //     }
  //   });
  // }


  Future<void> _getAppSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _spServerUrl.text = prefs.getString("spServerUrl") ?? '';
    _appServer.text = prefs.getString("appServer") ?? '';
    setState(() {
      if (_spServerUrl.text == '') {
        _spServerUrl.text = API_URL;
      } else {
        API_URL = _spServerUrl.text;
      }
      if (_appServer.text == '') {
        _appServer.text = APP_SERVER;
      } else {
        APP_SERVER = _appServer.text;
      }
      setValuesApi();
    });
  }

  void setValuesApi() {
    setState(() {
      IN_OUT_URL = API_URL + '/insert-update-emp-visit';
      EMP_DEVICE_URL = API_URL + '/';
    });
    _setImei();
  }



  AppBar _buildAppBar(){
    return AppBar(
      centerTitle: true,
      title: Text(APP_NAME),
      backgroundColor: Colors.orange,
      elevation: 10.0,
      shadowColor: Colors.red,
      toolbarTextStyle: const TextStyle(fontSize: 50),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [
              Color.fromARGB(255, 176, 106, 231),
              Color.fromARGB(255, 166, 112, 232),
              Color.fromARGB(255, 131, 123, 232),
              Color.fromARGB(255, 104, 132, 231),
            ],
            transform: GradientRotation(90)
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Scaffold(
        appBar: _buildAppBar(),
        body: Builder(builder: (BuildContext context) {
          return SingleChildScrollView(
            child: AbsorbPointer(
              absorbing: false,
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      // ignore: unnecessary_null_comparison
                      session.userEmployeeID == null
                          ? const Text(
                              "No user found!. ",
                              style: TextStyle(fontSize: 20),
                            )
                          : Row(
                              children: [
                                const Text(
                                  "Welcome, ",
                                  style: TextStyle(fontSize: 20),
                                ),
                                Text("${session.userFullName}",
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold
                                        )
                                       )
                              ],
                            )
                    ],
                  ),
                ),
                Container(
                  height: MediaQuery.of(context).size.height - 150,
                  width: MediaQuery.of(context).size.width,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          const SizedBox(
                            height: 10.0,
                          ),
                          _isStart == true
                              ? const Expanded(
                                  child: Center(
                                    child: Text(
                                      "Identifying Location.... \nMake sure device GPS is ON. ",
                                      style: TextStyle(color: Colors.redAccent),
                                    ),
                                  ),
                                )
                              : _lattitude == "UNKNOWN"
                                  ? const Expanded(
                                      child: Center(
                                        child: Text(
                                          "Device location not found!. Make sure device GPS is ON.",
                                          style: TextStyle(
                                              color: Colors.redAccent),
                                        ),
                                      ),
                                    )
                                  : Expanded(
                                      child: ButtonBar(
                                        alignment: MainAxisAlignment.center,
                                        buttonPadding: const EdgeInsets.all(40),
                                        children: <Widget>[
                                          ClipOval(
                                            child: Material(
                                              color: Colors.red, // button color
                                              child: InkWell(
                                                splashColor: Colors
                                                    .green, // inkwell color
                                                child: const SizedBox(
                                                    width: 100,
                                                    height: 100,
                                                    child: Center(
                                                        child: Text(
                                                      'IN',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 24,
                                                          color: Colors.white),
                                                    ))),
                                                onTap: () {
                                                  setState(() {
                                                    type = 1;
                                                  });
                                                  _scan(context);
                                                },
                                              ),
                                            ),
                                          ),
                                          ClipOval(
                                            child: Material(
                                              color: Colors.red, // button color
                                              child: InkWell(
                                                splashColor: Colors
                                                    .green, // inkwell color
                                                child: const SizedBox(
                                                    width: 100,
                                                    height: 100,
                                                    child: Center(
                                                        child: Text(
                                                      'OUT',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 24,
                                                          color: Colors.white),
                                                    ))),
                                                onTap: () {
                                                  setState(() {
                                                    type = 0;
                                                  });
                                                  _scan(context);
                                                },
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                          Text(
                              "lat: $_lattitude, long: $_longitude \n device ID:${session.userDeviceID} "),
                        ],
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          );
        }),
      ),
      onWillPop: () async {
        return true;
      },
    );
  }
  
  
  Future<void> _setImei() async {
    // String platformImei;
    // String deviceId;
    try {
      setState(() {
        _getDeviceDetails;
      });
      // var ImeiPlugin;
      // platformImei =
      //     await ImeiPlugin.getImei(shouldShowRequestPermissionRationale: false);
    } catch (e) {
      identifier = 'Failed to get platform version.';
      print(identifier);
    }

    if (!mounted) return;

    if (identifier == "") {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.ERROR,
        animType: AnimType.BOTTOMSLIDE,
        title: 'Error!',
        desc: 'Device ID not detected!. ',
        dismissOnTouchOutside: false,
        btnOkText: "Restart",
        btnOkColor: Colors.red,
        btnOkOnPress: () {
          Phoenix.rebirth(context);
        },
      ).show();
    } else {
      setState(() {
        // session.userImei = platformImei;
        session.userDeviceID = identifier;
      });
      getEmpDevice();
    }
  }

  
  Future<void> _getDeviceDetails() async {
    final DeviceInfoPlugin deviceInfoPlugin =  DeviceInfoPlugin();
      if (Platform.isAndroid){
        var build = await deviceInfoPlugin.androidInfo;
        setState(() {
         deviceName = build.model;
         deviceVersion  = build.version.toString();
         identifier = build.androidId;
        });
      }
      else if (Platform.isIOS){
        var data = await deviceInfoPlugin.iosInfo;
        setState(() {
          deviceName = data.name;
          deviceVersion = data.systemVersion;
          identifier = data.identifierForVendor;
        });
      }
  } 


  Future _scan(context) async {
    _barcode = '';
    try {
      // String barcode = await FlutterBarcodeScanner.scanBarcode(
      //     '#ff6666', 'Cancel', true, ScanMode.BARCODE);
      var carmeraStatus = await Permission.camera.status;
      if(carmeraStatus.isGranted) {
           String? barcode =  await scanner.scan();
            _scanEffect(true);
            setState(() {
              _barcode = barcode.toString();
              if (_barcode != '') {
                _inOut();
              } else {
                AwesomeDialog(
                  context: context,
                  dialogType: DialogType.ERROR,
                  animType: AnimType.BOTTOMSLIDE,
                  btnOkColor: Colors.red,
                  title: 'Error!',
                  desc: 'Invalid barcode!',
                  btnOkOnPress: () {},
                ).show();
              }
            });
          
      } else {
        var isGrant = await Permission.camera.request();
        if(isGrant.isGranted){
          String? barcode =  await scanner.scan();
            _scanEffect(true);
            setState(() {
              _barcode = barcode.toString();
              if (_barcode != '') {
                _inOut();
              } else {
                AwesomeDialog(
                  context: context,
                  dialogType: DialogType.ERROR,
                  animType: AnimType.BOTTOMSLIDE,
                  btnOkColor: Colors.red,
                  title: 'Error!',
                  desc: 'Invalid barcode!',
                  btnOkOnPress: () {},
                ).show();
              }
            });
        }
      }

        
       
    } catch (e) {
      print("Scanning is cancelled");
    }
  }
  
  Future _inOut() async {
    try {
      Dio dio =  Dio();
      print("employeeID: ${session.userEmployeeID}");
      print("type:  $type");
      print("locationID  0");
      print("lattitude  $_lattitude");
      print("longitude  $_longitude");
      print("isQRCode  0");
      print("locSessionID $_barcode");
      var formData = FormData.fromMap({
        "employeeID": session.userEmployeeID,
        "type": type,
        "locationID": 0,
        "lattitude": _lattitude,
        "longitude": _longitude,
        "isQRCode": 1,
        "locSessionID": _barcode
      });

      var response = await dio.post(IN_OUT_URL, data: formData,
          onSendProgress: (int sent, int total) {
        print("$sent $total");
      });

      if (response.data == null) {
        return null;
      }

      if (int.parse(response.data[0]['RETURN']) >= 0) {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.SUCCES,
          animType: AnimType.BOTTOMSLIDE,
          title: 'Successfully!',
          desc: '${response.data[0]['MESSAGE']}',
          btnOkOnPress: () {},
        ).show();
      } else {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.ERROR,
          animType: AnimType.BOTTOMSLIDE,
          title: 'Failed!',
          desc: '${response.data[0]['MESSAGE']}',
          btnOkOnPress: () {},
        ).show();
      }
    } catch (e) {
        AwesomeDialog(
        context: context,
        dialogType: DialogType.WARNING,
        animType: AnimType.BOTTOMSLIDE,
        title: 'Error!',
        desc: 'Server connection failed!. ',
        dismissOnTouchOutside: false,
        btnOkText: "Ok",
        btnOkColor: Colors.orangeAccent,
        btnOkOnPress: () {},
      ).show();
      print("Connecting to server failed!.");
    }
  }
  void _scanEffect(bool type) async {
    type == true ? errorScanPlayer.play() : scanPlayer.play();
    await Vibration.vibrate();  
  }


  Future getEmpDevice () async {
    try {
      Dio dio =  Dio();
      var formData = FormData.fromMap({"androidID": session.userDeviceID});
      var response = await dio.post(EMP_DEVICE_URL, data: formData,
          onSendProgress: (int sent, int total) {
            print("$sent $total");
      });
      // CHECKING IF DEVICE IS REGISTER
      if (response.data.length == 0) { // IF DEVICE ID NOT REGISTER PROMPT ERROR MESSAGE
        AwesomeDialog(
          context: context,
          dialogType: DialogType.ERROR, //DISPLAY ERROR DIALOG BOX 
          animType: AnimType.BOTTOMSLIDE,
          title: 'Failed!',
          desc:
              'Device not yet registered!. Please contact system administrator. \n User Device ID : ${session.userDeviceID}',
          dismissOnTouchOutside: false,
          btnOkText: "Close App",
          btnOkColor: Colors.red,
          btnOkOnPress: () {
            SystemChannels.platform.invokeMethod('SystemNavigator.pop');
          },
        )..show();
      } else {
          setState(() {
          session.userEmployeeID = int.parse(response.data[0]['Employee_ID']);
          session.userEmployeeNo = response.data[0]['EmployeeNo'];
          session.userFullName = response.data[0]['FullName'];
        });
      }
    } catch (e) {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.WARNING,
          animType: AnimType.BOTTOMSLIDE,
          title: 'Error!',
          desc: 'Server connection failed!. ',
          dismissOnTouchOutside: false,
          btnOkText: "Ok",
          btnOkColor: Colors.orangeAccent,
          btnOkOnPress: () {},
        )..show();
        print("Connecting to server failed!.");
    }
  }

  
}
