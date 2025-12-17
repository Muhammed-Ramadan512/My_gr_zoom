import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gr_zoom/gr_zoom.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // String _platformVersion = 'Unknown';
  // final _grZoomPlugin = Zoom();

  @override
  void initState() {
    super.initState();
  }

  late Timer timer;
  String _statusText = "Connecting to Zoom…";
  String meetingID = "83327793303";
  String meetingPassword = "07821563";
  String jwt =
      "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJhcHBLZXkiOiJVTndiclpmZFI0R1RVZU5lM3ZfcnZnIiwibW4iOiI4MzMyNzc5MzMwMyIsInJvbGUiOjAsImlhdCI6MTc2NTk3MTgyNywiZXhwIjoxNzY1OTc1NDI3LCJ0b2tlbkV4cCI6MTc2NTk3NTQyN30.zgdfksc2JsVyCqqsEmtnlG2KWyTbaCwlNkLNbpMWDb8";

  @override
  void dispose() {
    if (timer.isActive) {
      timer.cancel();
    }
    super.dispose();
  }

  joinMeeting(BuildContext context, userName, userId) {
    String _mapStatus(String code, [String? details]) {
      if (code == null) return "Unknown status";
      switch (code) {
        case "MEETING_STATUS_CONNECTING":
          return "Connecting to Zoom…";
        case "MEETING_STATUS_WAITINGFORHOST":
          return "Waiting for host to start the meeting…";
        case "MEETING_STATUS_IN_WAITING_ROOM":
          return "You are in the waiting room…";
        case "MEETING_STATUS_INMEETING":
          return "You're in the meeting ✅";
        case "MEETING_STATUS_RECONNECTING":
          return "Connection dropped, reconnecting…";
        case "MEETING_STATUS_DISCONNECTING":
          return "Leaving the meeting…";
        case "MEETING_STATUS_ENDED":
          return "Meeting ended.";
        case "MEETING_STATUS_FAILED":
          // details أحيانًا بيرجع سبب نصي
          return "Failed to join the meeting.${details != null && details.toString().trim().isNotEmpty ? " ($details)" : ""}";
        case "MEETING_STATUS_IDLE":
          return "Not connected.";
        default:
          return "Status: $code";
      }
    }

    // ignore: no_leading_underscores_for_local_identifiers
    bool _isMeetingEnded(String status) {
      if (status == null) return false;
      if (Platform.isAndroid) {
        return status == "MEETING_STATUS_FAILED" ||
            status == "MEETING_STATUS_ENDED" ||
            status == "MEETING_STATUS_DISCONNECTING";
      } else {
        return status == "MEETING_STATUS_FAILED" ||
            status == "MEETING_STATUS_IDLE" ||
            status == "MEETING_STATUS_ENDED";
      }
    }

    void _setStatus(String txt) {
      if (!mounted) return;
      setState(() => _statusText = txt);
    }

    void _toast(String msg) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: Duration(seconds: 2)),
      );
    }

    ZoomOptions zoomOptions = ZoomOptions(
      domain: "zoom.us",
      jwtToken: jwt,
      customAndroidUi: false,
    );

    if (zoomOptions.jwtToken == null || zoomOptions.jwtToken!.isEmpty) {
      _setStatus("Missing JWT token for Zoom.");
      _toast("JWT is required");
      return;
    }

    var meetingOptions = ZoomMeetingOptions(
        userId: userName ??
            "User", //pass username for join meeting only --- Any name eg:- EVILRATT.
        meetingId: meetingID, //pass meeting id for join meeting only
        meetingPassword:
            meetingPassword, //pass meeting password for join meeting only
        disableDialIn: "true",
        disableDrive: "true",
        disableInvite: "true",
        disableShare: "true",
        noAudio: "false",
        noDisconnectAudio: "false",
        meetingViewOptions: 1,
        customerKey: userId,
        watermark: "MMMMR");

    var zoom = Zoom();

    _setStatus("Initializing Zoom SDK…");

    zoom.init(zoomOptions).then((initResult) {
      debugPrint("Zoom init -> $initResult (type=${initResult.runtimeType})");

      // 3.3.1 ممكن يرجّع List أو bool
      int initCode = -1;
      // ignore: unnecessary_type_check
      if (initResult is List && initResult.isNotEmpty && initResult[0] is int) {
        initCode = initResult[0];
      } else if (initResult is bool) {
        initCode = (initResult as bool) ? 0 : 1;
      }

      if (initCode != 0) {
        _setStatus("Failed to initialize Zoom SDK.");
        _toast("Zoom init failed ($initCode)");
        return;
      }

      // حالة قبل الانضمام (أحيانًا بتفيد)
      zoom.meetingStatus("mettingID").then((st) {
        String? code =
            (st is List && st.length > 0 && st[0] is String) ? st[0] : null;
        String? det = (st is List && st.length > 1) ? st[1]?.toString() : null;
        debugPrint("[Status before join] $st");
        if (code != null) _setStatus(_mapStatus(code, det));
      }).catchError((_) {});

      _setStatus("Joining meeting…");

      zoom.joinMeeting(meetingOptions).then((joinOk) {
        debugPrint("joinMeeting -> $joinOk (type=${joinOk.runtimeType})");

        // في 3.3.1: bool فقط
        if (joinOk == true) {
          _setStatus("Connecting to Zoom…");
          _toast("✅ Joined successfully");

          // ابدأ متابعة الحالة كل ثانيتين
          timer = Timer.periodic(Duration(seconds: 2), (t) {
            zoom.meetingStatus(meetingID).then((st) {
              debugPrint("[Meeting Status] $st");
              String code = (st is List && st.length > 0 && st[0] is String)
                  ? st[0]
                  : null;
              String? det =
                  (st is List && st.length > 1) ? st[1]?.toString() : null;

              if (code != null) {
                _setStatus(_mapStatus(code, det));
                if (_isMeetingEnded(code)) {
                  if (timer != null) timer.cancel();
                }
              }
            }).catchError((e) {
              debugPrint("meetingStatus error: $e");
            });
          });
        } else {
          // join فشل: هنا بنعرض أسباب محتملة للمستخدم
          _setStatus(
              "Failed to join the meeting. Check meeting ID/password or token.");
          _toast("❌ Failed to join meeting");
        }
      }).catchError((e) {
        debugPrint("joinMeeting error: $e");
        _setStatus("Exception while joining meeting.");
        _toast("⚠️ Exception while joining");
      });
    }).catchError((e) {
      debugPrint("init error: $e");
      _setStatus("Exception while initializing Zoom SDK.");
      _toast("⚠️ Init exception");
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
                onPressed: () => joinMeeting(context, "MR", "1"),
                child: const Text("join meeting")),
          )),
    );
  }
}
