import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gr_zoom/gr_zoom.dart';
import 'package:screen_protector/screen_protector.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  final _grZoomPlugin = Zoom();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      await ScreenProtector.preventScreenshotOn();
    });
    // initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    // String platformVersion;
    // // Platform messages may fail, so we use a try/catch PlatformException.
    // // We also handle the message potentially returning null.
    // try {
    //   platformVersion = await _grZoomPlugin.getPlatformVersion() ??
    //       'Unknown platform version';
    // } on PlatformException {
    //   platformVersion = 'Failed to get platform version.';
    // }

    // // If the widget was removed from the tree while the asynchronous platform
    // // message was in flight, we want to discard the reply rather than calling
    // // setState to update our non-existent appearance.
    // if (!mounted) return;

    // setState(() {
    //   _platformVersion = platformVersion;
    // });
  }

  late Timer timer;

  @override
  void dispose() {
    if (timer.isActive) {
      timer.cancel();
    }
    super.dispose();
  }

  joinMeeting(BuildContext context, userName) {
    bool _isMeetingEnded(String status) {
      var result = false;

      if (Platform.isAndroid)
        result = status == "MEETING_STATUS_DISCONNECTING" ||
            status == "MEETING_STATUS_FAILED";
      else
        result = status == "MEETING_STATUS_IDLE";

      return result;
    }

    ZoomOptions zoomOptions = ZoomOptions(
      domain: "zoom.us",

      jwtToken:
          "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcHBLZXkiOiJnaFBHU04ybnlRVDl5UDMyMnNmM2F0WW43V2hROVE0QzJhWnIiLCJzZGtLZXkiOiJnaFBHU04ybnlRVDl5UDMyMnNmM2F0WW43V2hROVE0QzJhWnIiLCJtbiI6IjgzMzU2NTgzMjU4Iiwicm9sZSI6MSwiaWF0IjoxNzE1MTA0Mzg3LCJleHAiOjE3MTUxMDc5ODcsInRva2VuRXhwIjoxNzE1MTA3OTg3fQ.S6VbBcaftD_pvWriWLZ9r04MhUucNZYCIltJRTYIHPo",
      // appKey:
      //     "TfHhRiMpRZ33yVhBcSO4ZIOi9Ew1eLsp2GJJ", //API KEY FROM ZOOM - Sdk API Key
      // appSecret:
      //     "ZubMdRlYUeOa4HbQWFdcA8mxAamqYBvAVQS7", //API SECRET FROM ZOOM - Sdk API Secret
    );
    var meetingOptions = ZoomMeetingOptions(
        userId: userName ??
            "User", //pass username for join meeting only --- Any name eg:- EVILRATT.
        meetingId:
            "83356583258", //widget.meetingId, //pass meeting id for join meeting only
        meetingPassword: "123456",
        // widget
        //     .meetingPassword, //pass meeting password for join meeting only
        disableDialIn: "true",
        disableDrive: "true",
        disableInvite: "true",
        disableShare: "true",
        noAudio: "false",
        noDisconnectAudio: "false");

    var zoom = Zoom();
    // ZoomView(); //Zoom()
    zoom.init(zoomOptions).then((results) {
      print(results);
      if (results[0] == 0) {
        zoom
            .meetingStatus("83356583258"
                // widget.meetingId
                )
            .then((status) {
          print("[Meeting Status Stream] : " + status[0] + " - " + status[1]);
          if (_isMeetingEnded(status[0])) {
            print("[Meeting Status] :- Ended");
            timer.cancel();
          }
        });
        print("listen on event channel");
        zoom.joinMeeting(meetingOptions).then((joinMeetingResult) {
          timer = Timer.periodic(new Duration(seconds: 2), (timer) {
            zoom.meetingStatus(meetingOptions.meetingId).then((status) {
              print("[Meeting Status Polling] : " +
                  status[0] +
                  " - " +
                  status[1]);
            });
          });
        });
      }
    }).catchError((error) {
      print("[Error Generated] : " + error.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Plugin example app'),
          ),
          body: Center(
            child: TextButton(
                onPressed: () => joinMeeting(context, "MR"),
                child: Text("join meeting")),
          )),
    );
  }
}
