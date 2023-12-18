import 'dart:isolate';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:newep/service/ypassTaskHandler.dart';
import '../realm/SettingDBUtil.dart';
import '../screen/MainScreen.dart';

class YPassTaskSetting {
  static final YPassTaskSetting _instance = YPassTaskSetting._internal();

  factory YPassTaskSetting() {
    return _instance;
  }

  YPassTaskSetting._internal();

  ReceivePort? _receivePort;
  late BuildContext context;
  late GlobalKey<TopState> topKey;

  void setContext(BuildContext inputContext) {
    context = inputContext;
  }

  void setTopKey(GlobalKey<TopState> inputTopKey) {
    debugPrint("TopKey 들어갔냐?");
    topKey = inputTopKey;
  }

  //foureground task 기본 설정
  void _initForegroundTask() {
    FlutterForegroundTask.init(
      //안드로이드 설정
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'notification_channel_id',
        channelName: 'Foreground Notification',
        channelDescription:
            'This notification appears when the foreground service is running.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        //push 아이콘은 앱 아이콘 따라감(기본설정)
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
        enableVibration: true,
      ), //iOS 설정
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ), //push 관련 설정
      foregroundTaskOptions: const ForegroundTaskOptions(
        //interval (millisecond)마다 push 가능 (이걸 통해 onEvent로 주기적으로 BLE 스캔 작동시킴)
        interval: 500,
        //1번만 push설정
        isOnceEvent: false,
        allowWakeLock: true,
      ),
    );
  }

  //foreground task 시작 함수
  Future<bool> startForegroundTask() async {
    //permission check
    if (!await FlutterForegroundTask.canDrawOverlays) {
      final isGranted =
          await FlutterForegroundTask.openSystemAlertWindowSettings();
      if (!isGranted) {
        debugPrint('SYSTEM_ALERT_WINDOW permission denied!');
        return false;
      }
    }

    //foreground task랑 통신 가능한 port (수신)
    final ReceivePort? receivePort = FlutterForegroundTask.receivePort;
    final bool isRegistered = _registerReceivePort(receivePort);
    if (!isRegistered) {
      debugPrint('Failed to register receivePort!');
      return false;
    }

    //foreground task가 이미 작동 중인지 check
    if (await FlutterForegroundTask.isRunningService) {
      debugPrint("Foreground Already Running");
      return FlutterForegroundTask.restartService();
    } else {
      debugPrint("Foreground Start Running");
      return FlutterForegroundTask.startService(
        notificationTitle: 'Foreground Service is running',
        notificationText: '',
        callback: startCallback,
      );
    }
  }

  Future<bool> checkForegroundTask() {
    return FlutterForegroundTask.isRunningService;
  }

  //foreground task 정지
  Future<bool> stopForegroundTask() {
    debugPrint("꺼진드아아아");
    return FlutterForegroundTask.stopService();
  }

  //통신 port 수신 데이터 처리
  bool _registerReceivePort(ReceivePort? newReceivePort) {
    if (newReceivePort == null) {
      return false;
    }

    _closeReceivePort();

    _receivePort = newReceivePort;
    _receivePort?.listen((message) {
      debugPrint("명령어 왔다");
      if (message is int) {
        debugPrint('eventCount: $message');
      } else if (message is String) {
        if (message == 'onNotificationPressed') {
          Navigator.of(context).pushNamed('/');
        } else if (message == "bluetooth off") {
          debugPrint("스캔 끌게");
          //debugPrint("작동 체크 : ${Top.of(context)}");
          try {
            topKey.currentState?.onClickOnOffButton();
          } catch (e) {
            debugPrint("백그라운드 예외 처리");
            AndroidAlarmManager.cancel(123);
            SettingDataUtil().setStateOnOff(false);
          }
        }
      } else if (message is DateTime) {
        debugPrint('timestamp: ${message.toString()}');
      }
    });

    return _receivePort != null;
  }

  //통신 port 종료
  void _closeReceivePort() {
    _receivePort?.close();
    _receivePort = null;
  }

  //정확한 작동 원리는 파악 안됨
  T? _ambiguate<T>(T? value) => value;

  void init() {
    //foreground task 기본 설정
    _initForegroundTask();
    //port 설정 + foreground task 재시작 시 기존 port 가져오기
    _ambiguate(WidgetsBinding.instance)?.addPostFrameCallback((_) async {
      if (await FlutterForegroundTask.isRunningService) {
        final newReceivePort = FlutterForegroundTask.receivePort;
        _registerReceivePort(newReceivePort);
      }
    });
  }
}
