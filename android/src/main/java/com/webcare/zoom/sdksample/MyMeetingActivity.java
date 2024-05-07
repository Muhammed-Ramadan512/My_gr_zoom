package com.webcare.zoom.sdksample;

import android.os.Bundle;
import android.view.WindowManager;

import us.zoom.sdk.NewMeetingActivity;

public class MyMeetingActivity extends NewMeetingActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

       
            getWindow().setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE);
       

    }
}