package com.myapp.weplay_clone

import android.app.Application

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        // Pre-load TRTC native lib in Application classloader context.
        // Fixes JNI FindClass null on OPPO/ColorOS where the plugin
        // classloader doesn't have visibility of com.tencent.* classes.
        try {
            System.loadLibrary("liteavsdk")
        } catch (e: UnsatisfiedLinkError) {
            // Library will be loaded later by TRTCPlugin
        }
    }
}
