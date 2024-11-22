import 'dart:async';

import 'package:flutter/services.dart';

typedef ZLZResponse = Function(String? retCode, dynamic extInfo);

class FlutterZolozkit {
  static const MethodChannel _channel =
      const MethodChannel('com.zoloz.flutter.plugin/zolozkit');
  static ZLZResponse? _onCompletedCallback;
  static ZLZResponse? _onInterruptedCallback;

  static Future<String?> get metaInfo async {
    final String? metaInfo = await _channel.invokeMethod('getMetaInfo');
    return metaInfo;
  }

  static Future<String?> get zolozLocale async {
    String? metaInfo = await _channel.invokeMethod("getLocaleKey");
    return metaInfo;
  }

  static Future<String?> get zolozChameleonConfigPath async {
    String? metaInfo = await _channel.invokeMethod("getChameleonConfigPath");
    return metaInfo;
  }

  static Future<String?> get zolozPublicKey async {
    String? metaInfo = await _channel.invokeMethod("getPublicKey");
    return metaInfo;
  }

  static Future<void> _methodCallHandler(MethodCall call) async {
    print("dart method callhandler");
    final retCode = call.arguments["retCode"];
    final extInfo =  call.arguments["extInfo"];
    if(call.method == 'onCompleted'){
      _onCompletedCallback?.call(retCode, extInfo);
    }else if(call.method == 'onInterrupted'){
      _onInterruptedCallback?.call(retCode, extInfo);
    }
    _onCompletedCallback = null;
    _onInterruptedCallback = null;
  }

  static Future start(String clientCfg, Map bizCfg, ZLZResponse onInterrupted, ZLZResponse onCompleted) async {
    _channel.setMethodCallHandler(_methodCallHandler);
    _onCompletedCallback = onCompleted;
    _onInterruptedCallback = onInterrupted;
    await _channel.invokeMethod("start",
        {"clientCfg": clientCfg, "bizCfg": bizCfg == null ? {} : bizCfg});
  }
}
