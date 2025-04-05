import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gr_zoom/gr_zoom.dart';
import 'package:gr_zoom/gr_zoom_options.dart';

class ZoomJoinScreen extends StatefulWidget {
  final meetingPassword, meetingId, appSecret, appKey;

  final jwt;

  ZoomJoinScreen(
      {this.appKey,
      this.appSecret,
      this.meetingId,
      this.meetingPassword,
      this.jwt});
  @override
  _ZoomJoinScreenState createState() => _ZoomJoinScreenState();
}

class _ZoomJoinScreenState extends State<ZoomJoinScreen> {
  Timer timer;

  @override
  void dispose() async {
    super.dispose();
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      joinMeeting(context, "");
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.red,
          centerTitle: true,
          title: const Text(
            "Meeting Screen",
            maxLines: 2,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Center(
              child: Text(
                "Your Meeting will Start Soon or It has ended",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
            ),
          ],
        ));
  }

  joinMeeting(BuildContext context, userName) {
    bool _isMeetingEnded(String status) {
      var result = false;

      if (Platform.isAndroid) {
        result = status == "MEETING_STATUS_DISCONNECTING" ||
            status == "MEETING_STATUS_FAILED";
      } else {
        result = status == "MEETING_STATUS_IDLE";
      }

      return result;
    }

    ZoomOptions zoomOptions = ZoomOptions(
        domain: "zoom.us",
        jwtToken:
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcHBLZXkiOiJUMVZ0Qmtnd1JHYUtMb0dtdW5sWkJRIiwibW4iOiI4Njk3NjA5NzkzMCIsInJvbGUiOjAsImlhdCI6MTc0MzAzNzU1NywiZXhwIjoxNzQzMDQxMTU3LCJ0b2tlbkV4cCI6MTc0MzA0MTE1N30.Wz5dzQ0ioXpF9LUKH72CaoclnTcJOKxvXd--c30ouCU"
        // appKey: widget.appKey, //API KEY FROM ZOOM - Sdk API Key
        // appSecret: widget.appSecret,
        // disableScreenshotAndRecording: false,

        //API SECRET FROM ZOOM - Sdk API Secret
        );
    var meetingOptions = ZoomMeetingOptions(
      userId: userName ??
          "User", //pass username for join meeting only --- Any name eg:- EVILRATT.
      meetingId: "86976097930", //pass meeting id for join meeting only
      meetingPassword: "123456", //pass meeting password for join meeting only
      disableDialIn: "true",
      disableDrive: "true",
      disableInvite: "true",
      disableShare: "true",
      noAudio: "false",
      noDisconnectAudio: "false",
      meetingViewOptions: 0,
    );

    var zoom = Zoom();
    // ZoomView(); //Zoom()
    zoom.init(zoomOptions).then((results) {
      debugPrint(results.toString());
      if (results[0] == 0) {
        zoom.meetingStatus(widget.meetingId).then((status) {
          debugPrint(
              "[Meeting Status Stream] : " + status[0] + " - " + status[1]);
          if (_isMeetingEnded(status[0])) {
            debugPrint("[Meeting Status] :- Ended");
            timer.cancel();
          }
        });
        debugPrint("listen on event channel");
        zoom.joinMeeting(meetingOptions).then((joinMeetingResult) {
          timer = Timer.periodic(const Duration(seconds: 2), (timer) {
            zoom.meetingStatus(meetingOptions.meetingId).then((status) {
              debugPrint("[Meeting Status Polling] : " +
                  status[0] +
                  " - " +
                  status[1]);
            });
          });
        });
      }
    }).catchError((error) {
      debugPrint("[Error Generated] : " + error.toString());
    });
  }
}
