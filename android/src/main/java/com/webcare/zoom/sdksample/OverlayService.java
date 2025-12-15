package com.webcare.zoom.sdksample;

import android.app.Service;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.graphics.Color;
import android.os.Handler;
import android.os.IBinder;
import android.view.Gravity;
import android.view.WindowManager;
import android.widget.TextView;

import java.util.Random;

public class OverlayService extends Service {

    private WindowManager wmgr;
    private WindowManager.LayoutParams params;
    private TextView wm;
    private Handler handler = new Handler();
    private Random random = new Random();

    private boolean isVisible = false;
    private boolean destroyed = false;

    private BroadcastReceiver endReceiver;

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    @Override
    public void onCreate() {
        super.onCreate();

        // Listen for meeting end
        endReceiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                stopSelf();  // Kill overlay immediately
            }
        };

        registerReceiver(endReceiver, new IntentFilter("ZOOM_MEETING_ENDED"),
                Context.RECEIVER_NOT_EXPORTED);

        wmgr = (WindowManager) getSystemService(WINDOW_SERVICE);

        wm = new TextView(this);
        wm.setText(ZoomPlugin.watermarkText);
        wm.setTextColor(Color.WHITE);
        wm.setBackgroundColor(Color.parseColor("#55000000"));
        wm.setTextSize(16f);
        wm.setPadding(20, 10, 20, 10);

        params = new WindowManager.LayoutParams(
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE |
                        WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
                -3
        );

        params.gravity = Gravity.TOP | Gravity.END;
        params.x = 30;
        params.y = 30;

        try {
            wmgr.addView(wm, params);
            isVisible = true;
        } catch (Exception ignored) {}

        startMovement();
    }

    private void startMovement() {
        handler.postDelayed(new Runnable() {
            @Override
            public void run() {
                if (destroyed || !isVisible || wm == null) return;

                try {
                    params.x = random.nextInt(350);
                    params.y = random.nextInt(900);
                    wmgr.updateViewLayout(wm, params);
                } catch (Exception ignored) {}

                handler.postDelayed(this, 3000);
            }
        }, 3000);
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        destroyed = true;

        try {
            unregisterReceiver(endReceiver);
        } catch (Exception ignored) {}

        if (isVisible && wm != null) {
            try {
                wmgr.removeView(wm);
            } catch (Exception ignored) {}
        }

        wm = null;
        isVisible = false;
    }
}
