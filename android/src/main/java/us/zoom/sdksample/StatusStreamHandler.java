package us.zoom.sdksample;

import java.util.Arrays;
import java.util.List;

import io.flutter.plugin.common.EventChannel;
import us.zoom.sdk.MeetingError;
import us.zoom.sdk.MeetingService;
import us.zoom.sdk.MeetingServiceListener;
import us.zoom.sdk.MeetingStatus;
import us.zoom.sdk.MeetingParameter;

import android.content.Context;
import android.content.Intent;
import android.app.Activity;
import us.zoom.sdk.ZoomSDK;
import us.zoom.sdksample.inmeetingfunction.customizedmeetingui.MyMeetingActivity;

/**
 * This class implements the handler for the Zoom meeting event in the flutter event channel
 */
public class StatusStreamHandler implements EventChannel.StreamHandler {
    private MeetingService meetingService;
    private MeetingServiceListener statusListener;
    private Activity activity;
    private Context context;
    private ZoomSDK zoomSDK;


    public static String meetingName;

    public StatusStreamHandler(MeetingService meetingService) {
        this.meetingService = meetingService;
    }

    public StatusStreamHandler(MeetingService meetingService, Context context, Activity activity, ZoomSDK zoomSDK) {
        this.meetingService = meetingService;
        this.activity = activity;
        this.context = context;
        this.zoomSDK = zoomSDK;
    }

    @Override
    public void onListen(Object arguments, final EventChannel.EventSink events) {
        statusListener = new MeetingServiceListener() {
            @Override
            public void onMeetingStatusChanged(MeetingStatus meetingStatus, int errorCode, int internalErrorCode) {

                if(meetingStatus == MeetingStatus.MEETING_STATUS_FAILED &&
                        errorCode == MeetingError.MEETING_ERROR_CLIENT_INCOMPATIBLE) {
                    events.success(Arrays.asList("MEETING_STATUS_UNKNOWN", "Version of ZoomSDK is too low"));
                    return;
                }

                if (zoomSDK != null && zoomSDK.getMeetingSettingsHelper().isCustomizedMeetingUIEnabled()) {
                    if (meetingStatus == MeetingStatus.MEETING_STATUS_CONNECTING) {
                        MyMeetingActivity.previousActivity = activity;
                        MyMeetingActivity.meetingName = StatusStreamHandler.meetingName;
                        Intent intent = new Intent(context, MyMeetingActivity.class);
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                        context.startActivity(intent);
                    } else if (meetingStatus == MeetingStatus.MEETING_STATUS_IDLE) {
                        //onBackPressed();
                    }
                }

                events.success(getMeetingStatusMessage(meetingStatus));
            }
			
			@Override
			public void onMeetingParameterNotification(MeetingParameter meetingParameter) {
				System.out.println("On meeting parameter notification");
			}
        };

        this.meetingService.addListener(statusListener);
    }
    @Override
    public void onCancel(Object arguments) {
        this.meetingService.removeListener(statusListener);
    }
	
    private List<String> getMeetingStatusMessage(MeetingStatus meetingStatus) {
        String[] message = new String[2];

        message[0] = meetingStatus != null ? meetingStatus.name() : "";

        switch (meetingStatus) {
            case MEETING_STATUS_CONNECTING:
                message[1] = "Connect to the meeting server.";
                break;
            case MEETING_STATUS_DISCONNECTING:
                message[1] = "Disconnect the meeting server, user leaves meeting.";
                break;
            case MEETING_STATUS_FAILED:
                message[1] = "Failed to connect the meeting server.";
                break;
            case MEETING_STATUS_IDLE:
                message[1] = "No meeting is running";
                break;
            case MEETING_STATUS_IN_WAITING_ROOM:
                message[1] = "Participants who join the meeting before the start are in the waiting room.";
                break;
            case MEETING_STATUS_INMEETING:
                message[1] = "Meeting is ready and in process.";
                break;
            case MEETING_STATUS_RECONNECTING:
                message[1] = "Reconnecting meeting server.";
                break;
            case MEETING_STATUS_UNKNOWN:
                message[1] = "Unknown status.";
                break;
            case MEETING_STATUS_WAITINGFORHOST:
                message[1] = "Waiting for the host to start the meeting.";
                break;
            case MEETING_STATUS_WEBINAR_DEPROMOTE:
                message[1] = "Demote the attendees from the panelist.";
                break;
            case MEETING_STATUS_WEBINAR_PROMOTE:
                message[1] = "Upgrade the attendees to panelist in webinar.";
                break;
            default:
                message[1] = "No status available.";
                break;
        }

        return Arrays.asList(message);
    }
}
