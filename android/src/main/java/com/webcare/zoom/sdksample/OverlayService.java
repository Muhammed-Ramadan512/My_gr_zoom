package com.webcare.zoom.sdksample;

import android.app.Service;
import android.content.Intent;
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
    private boolean isRemoved = false;

    @Override
    public IBinder onBind(Intent intent) {
        return null; // خدمة overlay لا تحتاج Binder
    }

    @Override
    public void onCreate() {
        super.onCreate();

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
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY, // آمن بدون SYSTEM_ALERT_WINDOW
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE |
                        WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
                -3 // PixelFormat.TRANSLUCENT
        );

        params.gravity = Gravity.TOP | Gravity.END;
        params.x = 20;
        params.y = 20;

        try {
            wmgr.addView(wm, params);
        } catch (Exception e) {
            e.printStackTrace();
        }

        startMovement();
    }

    private void startMovement() {
        handler.postDelayed(new Runnable() {
            @Override
            public void run() {
                if (isRemoved || wm == null) return;

                try {
                    params.x = random.nextInt(300);
                    params.y = random.nextInt(800);
                    wmgr.updateViewLayout(wm, params);
                } catch (Exception ignored) {}

                handler.postDelayed(this, 3000); // إعادة الحركة
            }
        }, 3000);
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        isRemoved = true;

        try {
            if (wm != null) {
                wmgr.removeView(wm);
                wm = null;
            }
        } catch (Exception ignored) {}
    }
}
