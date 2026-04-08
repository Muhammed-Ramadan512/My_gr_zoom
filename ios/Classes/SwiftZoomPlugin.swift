import Flutter
import UIKit
import MobileRTC

public class SwiftZoomPlugin: NSObject, FlutterPlugin, FlutterStreamHandler, MobileRTCMeetingServiceDelegate {

    // MARK: - Meeting View Options
    struct MeetingViewOptions {
        static let NO_BUTTON_AUDIO = 2
        static let NO_BUTTON_LEAVE = 128
        static let NO_BUTTON_MORE = 16
        static let NO_BUTTON_PARTICIPANTS = 8
        static let NO_BUTTON_SHARE = 4
        static let NO_BUTTON_SWITCH_AUDIO_SOURCE = 512
        static let NO_BUTTON_SWITCH_CAMERA = 256
        static let NO_BUTTON_VIDEO = 1
        static let NO_TEXT_MEETING_ID = 32
        static let NO_TEXT_PASSWORD = 64
    }

    // MARK: - Properties
    var authenticationDelegate: AuthenticationDelegate
    var eventSink: FlutterEventSink?
    var isObserved: Bool = false

    private var overlayWindow: UIWindow?
    private var currentWatermarkText: String?
    private var watermarkTimer: Timer?
    private var watermarkLabel: UILabel?
    private var screenshotProtectionWindow: UIWindow?
    private var secureField: UITextField?

    // MARK: - Watermark
    private func showCustomWatermark(text: String?) {
        DispatchQueue.main.async {
            guard let text = text else { return }

            if self.overlayWindow == nil {
                if #available(iOS 13.0, *) {
                    if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                        self.overlayWindow = UIWindow(windowScene: scene)
                    }
                }
                if self.overlayWindow == nil {
                    self.overlayWindow = UIWindow(frame: UIScreen.main.bounds)
                }
                self.overlayWindow?.windowLevel = .alert + 1
                self.overlayWindow?.backgroundColor = .clear
                self.overlayWindow?.isUserInteractionEnabled = false
            }

            self.overlayWindow?.subviews.forEach { $0.removeFromSuperview() }

            let label = UILabel()
            label.text = text
            label.textColor = UIColor.gray.withAlphaComponent(0.4)
            label.numberOfLines = 0
            label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
            label.sizeToFit()

            let transform = CGAffineTransform(rotationAngle: -(.pi / 4))
            label.transform = transform
            label.center = CGPoint(x: self.overlayWindow!.bounds.width / 2, y: self.overlayWindow!.bounds.height / 2)

            self.overlayWindow?.addSubview(label)
            self.overlayWindow?.isHidden = false

            self.watermarkLabel = label
            self.startWatermarkAnimation()
        }
    }

    private func startWatermarkAnimation() {
        self.watermarkTimer?.invalidate()
        if #available(iOS 10.0, *) {
            self.watermarkTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
                guard let self = self, let label = self.watermarkLabel, let window = self.overlayWindow else { return }

                let maxX = window.bounds.width
                let maxY = window.bounds.height
                let newX = CGFloat.random(in: label.bounds.width / 2 ... maxX - label.bounds.width / 2)
                let newY = CGFloat.random(in: label.bounds.height / 2 ... maxY - label.bounds.height / 2)

                let colors: [UIColor] = [.red, .blue, .green, .orange, .purple, .cyan, .gray, .brown, .systemPink]
                let randomColor = colors.randomElement()!.withAlphaComponent(0.4)

                UIView.animate(withDuration: 3.0, delay: 0, options: [.curveEaseInOut, .allowUserInteraction], animations: {
                    label.center = CGPoint(x: newX, y: newY)
                    label.textColor = randomColor
                }, completion: nil)
            }
        }
    }

    // MARK: - Screenshot Blackout
    private func enableScreenshotBlackout() {
        DispatchQueue.main.async {
            guard self.screenshotProtectionWindow == nil else { return }
            var window: UIWindow?
            if #available(iOS 13.0, *) {
                if let scene = UIApplication.shared.connectedScenes
                    .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                    window = UIWindow(windowScene: scene)
                }
            }
            if window == nil {
                window = UIWindow(frame: UIScreen.main.bounds)
            }
            window?.windowLevel = UIWindow.Level.alert - 1
            window?.backgroundColor = .clear
            window?.isUserInteractionEnabled = false

            let field = UITextField(frame: window!.bounds)
            field.isSecureTextEntry = true
            field.backgroundColor = .clear
            field.isUserInteractionEnabled = false
            window?.addSubview(field)

            self.secureField = field
            self.screenshotProtectionWindow = window
            window?.isHidden = false
        }
    }

    private func disableScreenshotBlackout() {
        DispatchQueue.main.async {
            self.screenshotProtectionWindow?.isHidden = true
            self.screenshotProtectionWindow = nil
            self.secureField = nil
        }
    }

    // MARK: - Registration
    public static func register(with registrar: FlutterPluginRegistrar) {
        let messenger = registrar.messenger()
        let channel = FlutterMethodChannel(name: "plugins.webcare/zoom_channel", binaryMessenger: messenger)
        let instance = SwiftZoomPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)

        let eventChannel = FlutterEventChannel(name: "plugins.webcare/zoom_event_stream", binaryMessenger: messenger)
        eventChannel.setStreamHandler(instance)
    }

    override init() {
        authenticationDelegate = AuthenticationDelegate()
        super.init()
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.userDidTakeScreenshotNotification, object: nil)
        if #available(iOS 11.0, *) {
            NotificationCenter.default.removeObserver(self, name: UIScreen.capturedDidChangeNotification, object: nil)
        }
    }

    // MARK: - Screen Protection
    @objc private func handleScreenshot() {
        sendEventToFlutter(event: ["type": "screenshot_detected"])
        DispatchQueue.main.async {
            MobileRTC.shared().getMeetingService()?.leaveMeeting(with: .leave)
            self.showAlert(title: "تحذير", message: "لقد قمت بأخذ لقطة للشاشة. تم إخراجك من المحاضرة.")
        }
    }

    @objc private func screenCaptureChanged() {
        if #available(iOS 11.0, *) {
            let isCaptured = UIScreen.main.isCaptured
            if isCaptured {
                sendEventToFlutter(event: ["type": "screen_recording", "isCaptured": isCaptured])
                DispatchQueue.main.async {
                    MobileRTC.shared().getMeetingService()?.leaveMeeting(with: .leave)
                    self.showAlert(title: "تحذير", message: "لقد قمت بتسجيل الشاشة. تم إخراجك من المحاضرة.")
                }
            }
        }
    }

    private func sendEventToFlutter(event: [String: Any]) {
        if let sink = eventSink {
            sink(event)
        }
    }

    private func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            guard let rootVC = UIApplication.shared.keyWindow?.rootViewController else { return }
            var topVC = rootVC
            while let presented = topVC.presentedViewController {
                topVC = presented
            }
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "حسنا", style: .default, handler: nil))
            topVC.present(alert, animated: true, completion: nil)
        }
    }

    // MARK: - Method Channel Handler
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "init":
            self.initZoom(call: call, result: result)
        case "join":
            self.joinMeeting(call: call, result: result)
        case "start":
            self.startMeeting(call: call, result: result)
        case "meeting_status":
            self.meetingStatus(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Zoom Actions
    public func initZoom(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let pluginBundle = Bundle(for: type(of: self))
        let pluginBundlePath = pluginBundle.bundlePath
        let arguments = call.arguments as! Dictionary<String, String>

        let context = MobileRTCSDKInitContext()
        context.domain = arguments["domain"]!
        context.enableLog = true
        context.bundleResPath = pluginBundlePath
        MobileRTC.shared().initialize(context)

        let auth = MobileRTC.shared().getAuthService()
        auth?.delegate = self.authenticationDelegate.onAuth(result)
        if let jwtToken = arguments["jwtToken"] {
            auth?.jwtToken = jwtToken
        }
        auth?.sdkAuth()
    }

    public func meetingStatus(call: FlutterMethodCall, result: FlutterResult) {
        let meetingService = MobileRTC.shared().getMeetingService()
        if meetingService != nil {
            let meetingState = meetingService?.getMeetingState()
            result(getStateMessage(meetingState))
        } else {
            result(["MEETING_STATUS_UNKNOWN", ""])
        }
    }

    private func setupScreenProtection(arguments: Dictionary<String, String?>, result: FlutterResult) -> Bool {
        var isProtected = false
        if let val = arguments["enableScreenProtection"] as? String {
            isProtected = NSString(string: val).boolValue
        } else if let valStr = arguments["enableScreenProtection"] as? String?, let v = valStr {
            isProtected = NSString(string: v).boolValue
        }

        if isProtected {
            if #available(iOS 11.0, *) {
                if UIScreen.main.isCaptured {
                    self.showAlert(title: "تحذير", message: "لا يمكنك دخول المحاضرة أثناء تسجيل الشاشة. يرجى إيقاف التسجيل أولاً.")
                    self.sendEventToFlutter(event: ["type": "screen_recording", "isCaptured": true])
                    result(false)
                    return false
                }
            }
            if !isObserved {
                NotificationCenter.default.addObserver(self, selector: #selector(handleScreenshot), name: UIApplication.userDidTakeScreenshotNotification, object: nil)
                if #available(iOS 11.0, *) {
                    NotificationCenter.default.addObserver(self, selector: #selector(screenCaptureChanged), name: UIScreen.capturedDidChangeNotification, object: nil)
                }
                isObserved = true
            }
            self.enableScreenshotBlackout()
        } else {
            if isObserved {
                NotificationCenter.default.removeObserver(self, name: UIApplication.userDidTakeScreenshotNotification, object: nil)
                if #available(iOS 11.0, *) {
                    NotificationCenter.default.removeObserver(self, name: UIScreen.capturedDidChangeNotification, object: nil)
                }
                isObserved = false
            }
            self.disableScreenshotBlackout()
        }
        return true
    }

    private func applyMeetingSettings(_ meetingSettings: MobileRTCMeetingSettings?, arguments: Dictionary<String, String?>) {
        meetingSettings?.disableDriveMode(parseBoolean(data: arguments["disableDrive"]!, defaultValue: false))
        meetingSettings?.disableCall(in: parseBoolean(data: arguments["disableDialIn"]!, defaultValue: false))
        meetingSettings?.setAutoConnectInternetAudio(parseBoolean(data: arguments["noDisconnectAudio"]!, defaultValue: false))
        meetingSettings?.setMuteAudioWhenJoinMeeting(parseBoolean(data: arguments["noAudio"]!, defaultValue: false))
        meetingSettings?.meetingShareHidden = true
        meetingSettings?.meetingInviteHidden = true
        meetingSettings?.meetingMoreHidden = true
        meetingSettings?.meetingTitleHidden = true
        meetingSettings?.meetingPasswordHidden = true
        meetingSettings?.meetingInviteUrlHidden = true
        meetingSettings?.disableGalleryView(true)
        meetingSettings?.meetingParticipantHidden = true

        if arguments["meetingViewOptions"] != nil {
            meetingSettings?.meetingMoreHidden = false
            let meetingViewOptions = parseInt(data: arguments["meetingViewOptions"]!, defaultValue: 0)
            if (meetingViewOptions & MeetingViewOptions.NO_BUTTON_AUDIO) != 0 {
                meetingSettings?.meetingAudioHidden = true
            }
            if (meetingViewOptions & MeetingViewOptions.NO_BUTTON_LEAVE) != 0 {
                meetingSettings?.meetingLeaveHidden = true
            }
            if (meetingViewOptions & MeetingViewOptions.NO_BUTTON_MORE) != 0 {
                meetingSettings?.meetingMoreHidden = false
            }
            if (meetingViewOptions & MeetingViewOptions.NO_BUTTON_PARTICIPANTS) != 0 {
                meetingSettings?.meetingParticipantHidden = true
            }
            if (meetingViewOptions & MeetingViewOptions.NO_BUTTON_VIDEO) != 0 {
                meetingSettings?.meetingVideoHidden = false
            }
            if (meetingViewOptions & MeetingViewOptions.NO_TEXT_MEETING_ID) != 0 {
                meetingSettings?.meetingTitleHidden = true
            }
            if (meetingViewOptions & MeetingViewOptions.NO_TEXT_PASSWORD) != 0 {
                meetingSettings?.meetingPasswordHidden = true
            }
        }
    }

    public func joinMeeting(call: FlutterMethodCall, result: FlutterResult) {
        let arguments = call.arguments as! Dictionary<String, String?>

        guard setupScreenProtection(arguments: arguments, result: result) else { return }

        let meetingService = MobileRTC.shared().getMeetingService()
        let meetingSettings = MobileRTC.shared().getMeetingSettings()

        guard meetingService != nil else { result(false); return }

        self.currentWatermarkText = arguments["watermarkText"] ?? nil
        applyMeetingSettings(meetingSettings, arguments: arguments)

        let joinMeetingParameters = MobileRTCMeetingJoinParam()
        joinMeetingParameters.userName = arguments["userId"]!!
        joinMeetingParameters.meetingNumber = arguments["meetingId"]!!

        if arguments["meetingPassword"]! != nil {
            joinMeetingParameters.password = arguments["meetingPassword"]!!
        }

        let response = meetingService?.joinMeeting(with: joinMeetingParameters)
        if let response = response {
            print("Got response from join: \(response)")
        }
        result(true)
    }

    public func startMeeting(call: FlutterMethodCall, result: FlutterResult) {
        let arguments = call.arguments as! Dictionary<String, String?>

        guard setupScreenProtection(arguments: arguments, result: result) else { return }

        let meetingService = MobileRTC.shared().getMeetingService()
        let meetingSettings = MobileRTC.shared().getMeetingSettings()

        guard meetingService != nil else { result(false); return }

        self.currentWatermarkText = arguments["watermarkText"] ?? nil
        applyMeetingSettings(meetingSettings, arguments: arguments)

        let user = MobileRTCMeetingStartParam4WithoutLoginUser()
        user.userType = .apiUser
        user.meetingNumber = arguments["meetingId"]!!
        user.userName = arguments["displayName"]!!
        user.zak = arguments["zoomAccessToken"]!!

        let response = meetingService?.startMeeting(with: user)
        if let response = response {
            print("Got response from start: \(response)")
        }
        result(true)
    }

    // MARK: - Helpers
    private func parseBoolean(data: String?, defaultValue: Bool) -> Bool {
        guard let data = data else { return defaultValue }
        return NSString(string: data).boolValue
    }

    private func parseInt(data: String?, defaultValue: Int) -> Int {
        guard let data = data else { return defaultValue }
        return NSString(string: data).integerValue
    }

    // MARK: - MobileRTCMeetingServiceDelegate
    public func onMeetingError(_ error: MobileRTCMeetError, message: String?) {}

    public func onMeetingStateChange(_ state: MobileRTCMeetingState) {
        guard let eventSink = eventSink else { return }
        eventSink(getStateMessage(state))

        switch state {
        case .inMeeting:
            if let watermark = self.currentWatermarkText {
                self.showCustomWatermark(text: watermark)
            }
        case .idle, .ended, .failed, .disconnecting:
            DispatchQueue.main.async {
                self.watermarkTimer?.invalidate()
                self.watermarkTimer = nil
                self.overlayWindow?.isHidden = true
                self.overlayWindow = nil
            }
            self.disableScreenshotBlackout()
        default:
            break
        }
    }

    // MARK: - FlutterStreamHandler
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        let meetingService = MobileRTC.shared().getMeetingService()
        if meetingService == nil {
            return FlutterError(code: "Zoom SDK error", message: "ZoomSDK is not initialized", details: nil)
        }
        meetingService?.delegate = self
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }

    private func getStateMessage(_ state: MobileRTCMeetingState?) -> [String] {
        switch state {
        case .idle:
            return ["MEETING_STATUS_IDLE", "No meeting is running"]
        case .connecting:
            return ["MEETING_STATUS_CONNECTING", "Connect to the meeting server"]
        case .inMeeting:
            return ["MEETING_STATUS_INMEETING", "Meeting is ready and in process"]
        case .webinarPromote:
            return ["MEETING_STATUS_WEBINAR_PROMOTE", "Upgrade the attendees to panelist in webinar"]
        case .webinarDePromote:
            return ["MEETING_STATUS_WEBINAR_DEPROMOTE", "Demote the attendees from the panelist"]
        case .disconnecting:
            return ["MEETING_STATUS_DISCONNECTING", "Disconnect the meeting server, leave meeting status"]
        case .ended:
            return ["MEETING_STATUS_ENDED", "Meeting ends"]
        case .failed:
            return ["MEETING_STATUS_FAILED", "Failed to connect the meeting server"]
        case .reconnecting:
            return ["MEETING_STATUS_RECONNECTING", "Reconnecting meeting server status"]
        case .waitingForHost:
            return ["MEETING_STATUS_WAITINGFORHOST", "Waiting for the host to start the meeting"]
        case .inWaitingRoom:
            return ["MEETING_STATUS_IN_WAITING_ROOM", "Participants who join the meeting before the start are in the waiting room"]
        default:
            return ["MEETING_STATUS_UNKNOWN", "\(state?.rawValue ?? 9999)"]
        }
    }
}

// MARK: - AuthenticationDelegate
public class AuthenticationDelegate: NSObject, MobileRTCAuthDelegate {

    private var result: FlutterResult?

    public func onAuth(_ result: FlutterResult?) -> AuthenticationDelegate {
        self.result = result
        return self
    }

    public func onMobileRTCAuthReturn(_ returnValue: MobileRTCAuthError) {
        if returnValue == .success {
            self.result?([0, 0])
        } else {
            self.result?([1, 0])
        }
        self.result = nil
    }

    public func onMobileRTCLoginReturn(_ returnValue: Int) {}
    public func onMobileRTCLogoutReturn(_ returnValue: Int) {}
}
