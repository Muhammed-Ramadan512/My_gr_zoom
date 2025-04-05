package us.zoom.sdksample.inmeetingfunction.customizedmeetingui.emoji;

import us.zoom.sdk.IEmojiReactionController;
import us.zoom.sdk.IEmojiReactionControllerEvent;
import us.zoom.sdk.MobileRTCEmojiFeedbackType;
import us.zoom.sdk.SDKEmojiReactionType;
import us.zoom.sdk.ZoomSDK;
import us.zoom.sdksample.inmeetingfunction.customizedmeetingui.BaseCallback;
import us.zoom.sdksample.inmeetingfunction.customizedmeetingui.BaseEvent;

public class EmojiReactionCallback extends BaseCallback<EmojiReactionCallback.EmojiReactionEvent> {

    private EmojiReactionCallback() {
        init();
    }

    protected void init() {
        IEmojiReactionController emojiReactionController = ZoomSDK.getInstance().getInMeetingService().getEmojiReactionController();
        if (emojiReactionController != null) {
            emojiReactionController.setEvent(iEmojiReactionEvent);
        }
    }

    private static final class InstanceHolder {
        static final EmojiReactionCallback instance = new EmojiReactionCallback();
    }

    public static EmojiReactionCallback getInstance() {
        return InstanceHolder.instance;
    }

    private final IEmojiReactionControllerEvent iEmojiReactionEvent = new IEmojiReactionControllerEvent() {
        @Override
        public void onEmojiFeedbackReceived(long userId, MobileRTCEmojiFeedbackType feedbackType) {

        }

        @Override
        public void onEmojiFeedbackCanceled(long userId) {

        }

        @Override
        public void onEmojiReactionReceived(long sender_id, SDKEmojiReactionType type) {
            for (EmojiReactionEvent event : callbacks) {
                event.onEmojiReactionReceived(sender_id, type);
            }
        }

        @Override
        public void onEmojiReactionReceivedInWebinar(SDKEmojiReactionType type) {
            for (EmojiReactionEvent event : callbacks) {
                event.onEmojiReactionReceivedInWebinar(type);
            }
        }
    };

    public void addEvent(EmojiReactionEvent event) {
        super.addListener(event);


    }

    public void removeEvent(EmojiReactionEvent event) {
        super.removeListener(event);
    }

    public interface EmojiReactionEvent extends BaseEvent {
        void onEmojiReactionReceived(long sender_id, SDKEmojiReactionType type);

        void onEmojiReactionReceivedInWebinar(SDKEmojiReactionType type);
    }
}
