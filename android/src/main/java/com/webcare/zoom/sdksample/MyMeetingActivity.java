package com.webcare.zoom.sdksample;

import android.graphics.Color;
import android.os.Bundle;
import android.view.Gravity;
import android.view.WindowManager;
import android.widget.FrameLayout;
import android.widget.TextView;

import java.util.Random;

import us.zoom.sdk.NewMeetingActivity;

public class MyMeetingActivity extends NewMeetingActivity {

    private TextView watermarkView;
    private boolean stopped = false;
    private final Random random = new Random();

    private final Runnable moveRunnable = new Runnable() {
        @Override
        public void run() {
            if (stopped || watermarkView == null) return;

            FrameLayout.LayoutParams lp =
                    (FrameLayout.LayoutParams) watermarkView.getLayoutParams();

            int maxX = Math.max(50, rootWidth - 400);
            int maxY = Math.max(50, rootHeight - 200);

            lp.leftMargin = random.nextInt(maxX);
            lp.topMargin  = random.nextInt(maxY);
            lp.gravity = Gravity.TOP | Gravity.START;

            watermarkView.setLayoutParams(lp);

            // 🔁 الحركة مستمرة مهما حصل
            watermarkView.postDelayed(this, 3000);
        }
    };

    private int rootWidth = 400;
    private int rootHeight = 800;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // 🔒 منع Screenshot
        getWindow().setFlags(
                WindowManager.LayoutParams.FLAG_SECURE,
                WindowManager.LayoutParams.FLAG_SECURE
        );

        if (ZoomPlugin.watermarkText == null ||
            ZoomPlugin.watermarkText.trim().isEmpty()) {
            return;
        }

        addWatermark();
    }

    private void addWatermark() {
        FrameLayout root = findViewById(android.R.id.content);

        root.post(() -> {
            rootWidth = root.getWidth();
            rootHeight = root.getHeight();
        });

        watermarkView = new TextView(this);
        watermarkView.setText(ZoomPlugin.watermarkText);
        watermarkView.setTextColor(Color.WHITE);
        watermarkView.setBackgroundColor(Color.parseColor("#55000000"));
        watermarkView.setTextSize(14f);
        watermarkView.setPadding(18, 10, 18, 10);

        FrameLayout.LayoutParams lp = new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.WRAP_CONTENT,
                FrameLayout.LayoutParams.WRAP_CONTENT
        );
        lp.gravity = Gravity.TOP | Gravity.END;
        lp.topMargin = 30;
        lp.rightMargin = 30;

        root.addView(watermarkView, lp);

        // ▶️ ابدأ الحركة
        watermarkView.postDelayed(moveRunnable, 3000);
    }

    @Override
    protected void onDestroy() {
        stopped = true;

        if (watermarkView != null) {
            watermarkView.removeCallbacks(moveRunnable);
            watermarkView = null;
        }

        super.onDestroy();
    }
}
