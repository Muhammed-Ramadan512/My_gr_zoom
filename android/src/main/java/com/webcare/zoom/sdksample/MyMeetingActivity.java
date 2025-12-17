package com.webcare.zoom.sdksample;

import android.graphics.Color;
import android.os.Bundle;
import android.os.Handler;
import android.view.Gravity;
import android.view.WindowManager;
import android.widget.FrameLayout;
import android.widget.TextView;

import java.util.Random;

import us.zoom.sdk.NewMeetingActivity;

public class MyMeetingActivity extends NewMeetingActivity {

    private TextView wm;
    private final Handler handler = new Handler();
    private final Random random = new Random();
    private boolean stopped = false;

    @Override
protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);

    getWindow().setFlags(
        WindowManager.LayoutParams.FLAG_SECURE,
        WindowManager.LayoutParams.FLAG_SECURE
    );
    if (ZoomPlugin.watermarkText == null) return;
    addWatermark();
}

private void addWatermark() {
    FrameLayout root = findViewById(android.R.id.content);

    wm = new TextView(this);
    wm.setText(ZoomPlugin.watermarkText == null ? "" : ZoomPlugin.watermarkText);
    wm.setTextColor(Color.WHITE);
    wm.setBackgroundColor(Color.parseColor("#55000000"));
    wm.setTextSize(14f);
    wm.setPadding(18, 10, 18, 10);

    FrameLayout.LayoutParams lp = new FrameLayout.LayoutParams(
        FrameLayout.LayoutParams.WRAP_CONTENT,
        FrameLayout.LayoutParams.WRAP_CONTENT
    );
    lp.gravity = Gravity.TOP | Gravity.END;
    lp.topMargin = 30;
    lp.rightMargin = 30;

    root.addView(wm, lp);

    root.post(() -> moveEvery3Seconds());
}

private void moveEvery3Seconds() {
    handler.postDelayed(new Runnable() {
        @Override
        public void run() {
            if (stopped || wm == null) return;

            FrameLayout.LayoutParams lp =
                (FrameLayout.LayoutParams) wm.getLayoutParams();

            int dw = getWindow().getDecorView().getWidth();
            int dh = getWindow().getDecorView().getHeight();

            int maxX = Math.max(50, dw - 400);
            int maxY = Math.max(50, dh - 200);

            lp.leftMargin = random.nextInt(maxX);
            lp.topMargin = random.nextInt(maxY);
            lp.gravity = Gravity.TOP | Gravity.START;

            wm.setLayoutParams(lp);

            handler.postDelayed(this, 3000);
        }
    }, 3000);
}

@Override
protected void onStop() {
    stopped = true;
    handler.removeCallbacksAndMessages(null);
    super.onStop();
}

@Override
protected void onDestroy() {
    stopped = true;
    handler.removeCallbacksAndMessages(null);
    wm = null;
    super.onDestroy();
}

}
