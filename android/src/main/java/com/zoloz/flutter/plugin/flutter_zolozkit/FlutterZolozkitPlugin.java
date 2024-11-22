package com.zoloz.flutter.plugin.flutter_zolozkit;

import android.app.Activity;
import android.content.Context;
import android.os.Handler;
import android.os.Looper;

import androidx.annotation.NonNull;

import java.lang.ref.WeakReference;
import java.util.HashMap;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

import com.ap.zoloz.hummer.api.*;

/**
 * FlutterZolozkitPlugin
 */
public class FlutterZolozkitPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {
    private MethodChannel channel;
    private Context mApplicationContext;
    private WeakReference<Activity> mActivity;
    private Handler mHandler = new Handler(Looper.getMainLooper());

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        mApplicationContext = flutterPluginBinding.getApplicationContext();
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "com.zoloz.flutter.plugin/zolozkit");
        channel.setMethodCallHandler(this);
    }


    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        mActivity = new WeakReference<>(binding.getActivity());
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {

    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        mActivity = new WeakReference<>(binding.getActivity());
    }

    @Override
    public void onDetachedFromActivity() {

    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        if (call.method.equals("getMetaInfo")) {
            result.success(ZLZFacade.getMetaInfo(mApplicationContext));
        } else if (call.method.equals("start")) {
            startZoloz(call, result);
        } else if (call.method.equals("getLocaleKey")) {
            result.success(ZLZConstants.LOCALE);
        } else if (call.method.equals("getChameleonConfigPath")) {
            result.success(ZLZConstants.CHAMELEON_CONFIG_PATH);
        } else if (call.method.equals("getPublicKey")) {
            result.success(ZLZConstants.PUBLIC_KEY);
        } else {
            result.notImplemented();
        }
    }


    private void callResult(final ZLZResponse zlzResponse, final boolean complete) {
        mHandler.post(new Runnable() {
            @Override
            public void run() {
                Map result = new HashMap<String, Object>() {{
                    put("retCode", zlzResponse.retCode);
                    put("extInfo", zlzResponse.extInfo);
                }};
                channel.invokeMethod(complete ? "onCompleted" : "onInterrupted", result);
            }
        });
    }

    private void startZoloz(final MethodCall call, Result result) {
        Context context = mActivity.get();
        if (context == null) {
            result.success("Can not get Activity!");
            return;
        }
        ZLZRequest request = new ZLZRequest();
        request.zlzConfig = call.argument("clientCfg");
        request.bizConfig = new HashMap<>();
        Map<String, String> bizCfg = call.argument("bizCfg");
        request.bizConfig.putAll(bizCfg);
        request.bizConfig.put(ZLZConstants.CONTEXT, context);
        ZLZFacade.getInstance().start(request, new IZLZCallback() {
            @Override
            public void onCompleted(ZLZResponse zlzResponse) {
                callResult(zlzResponse, true);
            }

            @Override
            public void onInterrupted(ZLZResponse zlzResponse) {
                callResult(zlzResponse, false);
            }
        });
    }
}
