package com.webcare.zoom.sdksample.inmeetingfunction.customizedmeetingui.bo;

import us.zoom.sdk.BOControllerError;
import us.zoom.sdk.IBOAdmin;
import us.zoom.sdk.IBOAdminEvent;
import us.zoom.sdk.ZoomSDK;
import com.webcare.zoom.sdksample.inmeetingfunction.customizedmeetingui.BaseCallback;
import com.webcare.zoom.sdksample.inmeetingfunction.customizedmeetingui.BaseEvent;

public class BOEventCallback extends BaseCallback<BOEventCallback.BOEvent> {
    private static BOEventCallback instance;

    private BOEventCallback() {
        init();
    }

    protected void init() {
        IBOAdmin iboAdmin = ZoomSDK.getInstance().getInMeetingService().getInMeetingBOController().getBOAdminHelper();
        if(iboAdmin != null)
            iboAdmin.setEvent(iboAdminEvent);
    }

    public static BOEventCallback getInstance() {
        if (null == instance) {
            synchronized (BOEventCallback.class) {
                if (null == instance) {
                    instance = new BOEventCallback();
                }
            }
        }
        return instance;
    }

    private IBOAdminEvent iboAdminEvent = new IBOAdminEvent() {
        @Override
        public void onHelpRequestReceived(String strUserID) {
            for (BOEvent event : callbacks) {
                event.onHelpRequestReceived(strUserID);
            }
        }

        @Override
        public void onStartBOError(BOControllerError error) {
            for (BOEvent event : callbacks) {
                event.onStartBOError(error);
            }
        }

        @Override
        public void onBOEndTimerUpdated(int remaining, boolean isTimesUpNotice) {
            for (BOEvent event : callbacks) {
                event.onBOEndTimerUpdated(remaining, isTimesUpNotice);
            }
        }

        @Override
        public void onStopBOResponse(boolean success) {
            // Added for Zoom SDK 7.x compatibility — no-op stub
        }

        @Override
        public void onStartBOResponse(boolean success) {
            // Added for Zoom SDK 7.x compatibility — no-op stub
        }
    };

    public void addEvent(BOEvent event) {
        super.addListener(event);

        IBOAdmin iboAdmin = ZoomSDK.getInstance().getInMeetingService().getInMeetingBOController().getBOAdminHelper();
        if(iboAdmin != null)
            iboAdmin.setEvent(iboAdminEvent);
    }

    public void removeEvent(BOEvent event) {
        super.removeListener(event);
    }

    public interface BOEvent extends BaseEvent {
        void onHelpRequestReceived(String strUserID);
        void onStartBOError(BOControllerError error);
        void onBOEndTimerUpdated(int remaining, boolean isTimesUpNotice);
    }
}
