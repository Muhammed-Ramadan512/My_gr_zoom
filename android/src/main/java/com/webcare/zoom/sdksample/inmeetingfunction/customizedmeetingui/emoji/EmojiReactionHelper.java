package com.webcare.zoom.sdksample.inmeetingfunction.customizedmeetingui.emoji;

import static us.zoom.sdk.SDKEmojiReactionType.*;

import us.zoom.sdk.SDKEmojiReactionType;
import com.webcare.zoom.sdksample.R;

public class EmojiReactionHelper {

    public static int getEmojiReactionDrawableId(SDKEmojiReactionType emojiType) {
        switch (emojiType) {
            case Clap:
                return R.drawable.reaction_clap;
            case Thumbsup:
                return R.drawable.reaction_thumbup;
            case Heart:
                return R.drawable.reaction_heart;
            case Joy:
                return R.drawable.reaction_joy;
            case Openmouth:
                return R.drawable.reaction_openmouth;
            case Tada:
                return R.drawable.reaction_tada;
        }
        return 0;
    }
}
