package com.webcare.zoom.sdksample.inmeetingfunction.customizedmeetingui.view.adapter;

import android.content.Context;

import androidx.recyclerview.widget.RecyclerView;

import android.os.Handler;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import us.zoom.sdk.InMeetingService;
import us.zoom.sdk.InMeetingUserInfo;
import us.zoom.sdk.MobileRTCVideoUnitAspectMode;
import us.zoom.sdk.MobileRTCVideoUnitRenderInfo;
import us.zoom.sdk.MobileRTCVideoView;
import us.zoom.sdk.SDKEmojiReactionType;
import us.zoom.sdk.ZoomSDK;
import com.webcare.zoom.sdksample.R;
import com.webcare.zoom.sdksample.inmeetingfunction.customizedmeetingui.emoji.EmojiReactionHelper;

public class AttenderVideoAdapter extends RecyclerView.Adapter<AttenderVideoAdapter.ViewHold> {
    public static final int REACTION_DURATION = 5000;

    public interface ItemClickListener {
        void onItemClick(View view, int position, long userId);
    }

    List<Long> userList = new ArrayList<>();

    private Map<Long, EmojiParams> emojiUsers = new HashMap<>();

    Context context;

    private int itemSize = 200;

    private ItemClickListener listener;

    int selected = -1;

    View selectedView;

    private Handler handler = new Handler();

    public static class EmojiParams {
        public long userId;
        public SDKEmojiReactionType reactionType;
        public Runnable runnable;

        public EmojiParams(long userId, SDKEmojiReactionType reactionType) {
            this.userId = userId;
            this.reactionType = reactionType;
        }
    }

    public AttenderVideoAdapter(Context context, int viewWidth, ItemClickListener listener) {
        this.context = context;
        this.listener = listener;
        if (viewWidth > 0) {
            itemSize = (viewWidth - 40) / 4;
        }
    }

    public void updateSize(int size) {
        itemSize = size;
        notifyDataSetChanged();
    }


    @Override
    public ViewHold onCreateViewHolder(ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(context).inflate(R.layout.item_attend, parent, false);
        RecyclerView.LayoutParams params = (RecyclerView.LayoutParams) view.getLayoutParams();
        params.width = itemSize;
        params.height = itemSize;
        view.setLayoutParams(params);

        view.setOnClickListener(onClickListener);

        return new ViewHold(view);
    }

    private View.OnClickListener onClickListener = new View.OnClickListener() {
        @Override
        public void onClick(View view) {
            Long userId = (Long) view.getTag();
            if (userId == getSelectedUserId()) {
                return;
            }
            if (null != listener) {
                int position = userList.indexOf(userId);
                if (position >= userList.size()) {
                    return;
                }
                listener.onItemClick(view, position, userId);
                if (null != selectedView) {
                    selectedView.setBackgroundResource(0);
                }
                view.setBackgroundResource(R.drawable.video_bg);
                selectedView = view;
                selected = position;
            }
        }
    };

    public void setUserList(List<Long> userList) {
        this.userList.clear();
        if (null != userList) {
            List<Long> retUserList = new ArrayList<>();
            for (Long userId : userList) {
                if (!isWebinarAttendee(userId)) {
                    retUserList.add(userId);
                }
            }

            if (!retUserList.isEmpty()) {
                this.userList.addAll(retUserList);
            }
        }
    }

    @Override
    public void onBindViewHolder(ViewHold holder, int position) {
        Long userId = userList.get(position);
        holder.videoView.getVideoViewManager().removeAllAttendeeVideoUnit();
        holder.videoView.getVideoViewManager().addAttendeeVideoUnit(userId, holder.renderInfo);
        holder.root.setTag(userId);
        holder.videoView.setTag(position);
        EmojiParams emojiParams = emojiUsers.get(userId);
        if (emojiParams != null) {
            int drawableId = EmojiReactionHelper.getEmojiReactionDrawableId(emojiParams.reactionType);
            if (drawableId == 0) {
                holder.ivEmoji.setVisibility(View.GONE);
                return;
            }
            holder.ivEmoji.setVisibility(View.VISIBLE);
            holder.ivEmoji.setImageDrawable(context.getResources().getDrawable(drawableId, null));
        } else {
            holder.ivEmoji.setVisibility(View.GONE);
        }


        if (position == selected) {
            if (null != selectedView) {
                selectedView.setBackgroundResource(0);
            }
            holder.root.setBackgroundResource(R.drawable.video_bg);
            selectedView = holder.root;
        } else {
            holder.root.setBackgroundResource(0);
        }
    }

    public void addUserList(List<Long> list) {
        for (Long userId : list) {
            if (!userList.contains(userId) && !isWebinarAttendee(userId)) {
                userList.add(userId);
                notifyItemInserted(userList.size());
            }
        }
    }

    public void setEmojiUser(EmojiParams emojiParams) {
        EmojiParams existedEmojiParams = emojiUsers.put(emojiParams.userId, emojiParams);
        if (existedEmojiParams != null && existedEmojiParams.runnable != null) {
            handler.removeCallbacks(existedEmojiParams.runnable);
        }
        int index = userList.indexOf(emojiParams.userId);
        notifyItemChanged(index);

        emojiParams.runnable = () -> {
            emojiUsers.remove(emojiParams.userId);
            int pos = userList.indexOf(emojiParams.userId);
            notifyItemChanged(pos);
        };

        handler.postDelayed(emojiParams.runnable, REACTION_DURATION);
    }

    public long getSelectedUserId() {
        if (selected >= 0 && selected < userList.size()) {
            return userList.get(selected);
        }
        return -1;
    }

    public void removeUserList(List<Long> list) {
        if (null == list) {
            return;
        }
        for (Long userId : list) {
            if (userList.indexOf(userId) >= 0) {
                int index = userList.indexOf(userId);
                userList.remove(index);
                if (index == selected) {
                    selected = 0;
                    notifyItemChanged(selected);
                }
                notifyItemRemoved(index);
            }
        }
    }

    @Override
    public int getItemCount() {
        return null == userList ? 0 : userList.size();
    }
    
    public void clear() {
        handler.removeCallbacksAndMessages(null);
    }

    public boolean isWebinarAttendee(long userId) {
        InMeetingService inMeetingService = ZoomSDK.getInstance().getInMeetingService();
        if (inMeetingService == null) {
            return false;
        }
        if (!inMeetingService.isWebinarMeeting()) {
            return false;
        }

        InMeetingUserInfo userInfo = inMeetingService.getUserInfoById(userId);
        return userInfo != null && userInfo.getInMeetingUserRole() == InMeetingUserInfo.InMeetingUserRole.USERROLE_ATTENDEE;
    }

    class ViewHold extends RecyclerView.ViewHolder {

        View root;
        MobileRTCVideoView videoView;
        MobileRTCVideoUnitRenderInfo renderInfo;
        ImageView ivEmoji;

        ViewHold(View view) {
            super(view);
            root = view;
            videoView = view.findViewById(R.id.item_videoView);
            ivEmoji = view.findViewById(R.id.iv_emoji);
            videoView.setZOrderMediaOverlay(true);
            renderInfo = new MobileRTCVideoUnitRenderInfo(0, 0, 100, 100);
            renderInfo.aspect_mode = MobileRTCVideoUnitAspectMode.VIDEO_ASPECT_PAN_AND_SCAN;
            renderInfo.is_show_audio_off = true;
            renderInfo.is_username_visible = true;
            renderInfo.is_border_visible = true;
//            renderInfo.aspect_mode = MobileRTCVideoUnitAspectMode.VIDEO_ASPECT_FULL_FILLED;
        }

    }
}
