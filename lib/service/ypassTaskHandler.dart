import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:newep/service/scanService.dart';
import 'package:newep/service/sensor/BleScan.dart';
import 'package:newep/service/ypassTaskSetting.dart';


//foreground task 시작
@pragma('vm:entry-point')
void startCallback() {
  //Foreground task는 main app 작동과 분리되므로 여기도 instance 초기화 보장 한번 더
  //안하면 ble 스캔 안됨
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.setTaskHandler(YPassTaskHandler());
}

//foreground 작동
class YPassTaskHandler extends TaskHandler {
  SendPort? _sendPort;
  bool isAnd = Platform.isAndroid;
  bool isClosing = false;

  ScanService service = ScanService();
  BleScanService ble = BleScanService();

  //gps는 더미 코드
  //LocationService gps = LocationService();

  YPassTaskSetting taskSetting = YPassTaskSetting();
  bool starting = false;

  //알림창 기본 설정
  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    _sendPort = sendPort;
    if (isAnd) {
      await service.onStart();
    }
    starting = true;
  }

  //push가 올 때마다 실행
  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
    if (!starting) {
      return;
    }
    if (isAnd) {
      // if (!await ble.flutterBlue.isOn) {
      /// note 여기
      if (true) {
        debugPrint("블루투스 꺼졌다.");
        if (!isClosing) {
          isClosing = true;
          _sendPort?.send('bluetooth off');
          taskSetting.stopForegroundTask();
        }
      } else {
        service.onEvent();
      }
    }
  }

  //foreground task가 끝날 때
  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    await FlutterForegroundTask.clearAllData();
    if (isAnd) {
      await service.onClose();
    }
    await Future.delayed(const Duration(milliseconds: 50));
    debugPrint("다 끝나고?");
  }

  //push안에 버튼을 눌렀을 때 (여기선 버튼 구현 안함)
  @override
  void onButtonPressed(String id) {
    debugPrint('onButtonPressed >> $id');
  }

  //push를 직접 눌렀을 때
  @override
  void onNotificationPressed() {
    if (Platform.isAndroid) {
      //앱이 워하는 route로 실행됨 (materialApp에서 route설정 해야함)
      FlutterForegroundTask.launchApp("/");
    }
    _sendPort?.send('onNotificationPressed');
  }
}
