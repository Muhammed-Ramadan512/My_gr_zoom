class ZoomOptions {
  String domain;
  String? jwtToken;
  bool? customAndroidUi;

  ZoomOptions({required this.domain, this.jwtToken, this.customAndroidUi});
}

class ZoomMeetingOptions {
  static const NO_BUTTON_AUDIO = 2;
  static const NO_BUTTON_LEAVE = 128;
  static const NO_BUTTON_MORE = 16;
  static const NO_BUTTON_PARTICIPANTS = 8;
  static const NO_BUTTON_SHARE = 4;
  static const NO_BUTTON_SWITCH_AUDIO_SOURCE = 512;
  static const NO_BUTTON_SWITCH_CAMERA = 256;
  static const NO_BUTTON_VIDEO = 1;
  static const NO_TEXT_MEETING_ID = 32;
  static const NO_TEXT_PASSWORD = 64;

  String userId;
  String? displayName;
  String meetingId;
  String meetingPassword;
  String? zoomToken;
  String? zoomAccessToken;
  String disableDialIn;
  String disableDrive;
  String disableInvite;
  String disableShare;
  String noDisconnectAudio;
  String noAudio;
  int? meetingViewOptions;
  String? meetingName;

  ZoomMeetingOptions({
    required this.userId,
    required this.meetingId,
    required this.meetingPassword,
    this.displayName,
    this.zoomToken,
    this.zoomAccessToken,
    required this.disableDialIn,
    required this.disableDrive,
    required this.disableInvite,
    required this.disableShare,
    required this.noDisconnectAudio,
    required this.noAudio,
    this.meetingViewOptions,
    this.meetingName
  });
}
