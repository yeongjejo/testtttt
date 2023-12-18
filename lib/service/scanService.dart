import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:newep/service/sensor/BleScan.dart';
import 'package:newep/service/ypassTaskSetting.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../constant/APPInfo.dart';
import '../http/HttpPostData.dart';
import '../http/NetworkState.dart';
import '../http/StatisticsReporter.dart';
import '../http/UserDataRequest.dart';
import '../realm/UserDBUtil.dart';

class ScanService {
  bool isAnd = Platform.isAndroid;
  bool isClosing = false;
  bool rebootWaiting = false;

  //ble 시작
  BleScanService ble = BleScanService();
  UserDBUtil db = UserDBUtil();
  late PackageInfo packageInfo;

  late String netState;
  late bool netCheck;
  bool starting = false;

  YPassTaskSetting taskSetting = YPassTaskSetting();

  Future<void> onStart() async {

    packageInfo = await PackageInfo.fromPlatform();
    APP_VERSION = packageInfo.version;
    netState = await checkNetwork();
    netCheck = netState != "인터넷 연결 안됨";

    //ble init
    ble.initBle();
    db.getDB();

    //사용기간 체크해서 UserData갱신
    var find = db.getUser();
    DateTime sDate = DateTime.parse(find.sDate);
    DateTime eDate = DateTime.parse(find.eDate);
    debugPrint("sDate : $sDate");
    debugPrint("eDate : $eDate");

    DateTime now = DateTime.now();
    int vaildTime = eDate.millisecondsSinceEpoch - sDate.millisecondsSinceEpoch;
    int useTime = now.millisecondsSinceEpoch - sDate.millisecondsSinceEpoch;
    debugPrint("sDate ~ eDate : $vaildTime");
    debugPrint("sDate ~ Now : $useTime");
    if (vaildTime < useTime * 3) {
      debugPrint("Update UserData");
      debugPrint("phoneNumber : ${find.phoneNumber}");
      debugPrint("갱신 시작");
      try {
        await UserDataRequest().setUserData(find.phoneNumber);
      } catch (e) {
        debugPrint("error : $e");
      }
    } else {
      debugPrint("Not Update Time");
    }
    //표시되는 push 창 업데이트
    debugPrint("Network Check : $netCheck");
    FlutterForegroundTask.updateService(
      notificationTitle: 'YPass',
      notificationText: netCheck ? "" : '인터넷이 연결되어 있지 않아, 정상 작동이 안될 수 있습니다.',
    );
    starting = true;
  }

  Future<void> onEvent() async {
    //gps 더미 코드
    //gps.getLocation();
    if (!starting) {
      return;
    }
    String temp = await checkNetwork();
    // debugPrint("Network Check : $netCheck, NetState Check : $netState, now : $temp");
    if (netState != temp) {
      netState = temp;
      netCheck = netState != "인터넷 연결 안됨";
      FlutterForegroundTask.updateService(
        notificationTitle: 'YPass',
        notificationText: netCheck ? "" : '인터넷이 연결되어 있지 않아, 정상 작동이 안될 수 있습니다.',
      );
    }
    try {
      if (!rebootWaiting) {
        if (ble.scanRestart && !ble.connecting) {
          await ble.scan();
        }
        await Future.delayed(const Duration(microseconds: 100));
        //스캔 결과 따라 Clober search
        if (ble.scanDone && !ble.connecting) {
          // debugPrint("BLE Scan Success!!");
          await ble.searchClober();
        }

        await Future.delayed(const Duration(microseconds: 100));
        //clober search 결과 따라
        if (ble.searchDone && !ble.connecting) {
          if (ble.findClober()) {
            if (isAnd) {
              // debugPrint("IsAndroid from Foreground");
              try {
                await ble.writeBle();
              } catch (e) {
                // debugPrint("Error log : ${e.toString()}");
              }
            } else {
              // debugPrint("IsiOS from Foreground");
              try {
                await ble.connect().then((value) {
                  ble.disconnect();
                });
              } catch (e) {
                ble.disconnect();
                // debugPrint("Connect Error!!!");
              }
            }
          } else {
            // debugPrint("Clober not Found");
          }
        }
      }
    } catch (e) {
      debugPrint("error : $e");
      rebootWaiting = true;
      ble.stopScan();
      ble.disposeBle();
      ble.disconnect();
      ble.initBle();
      StatisticsReporter()
          .sendError('Scan 전 설정 오류 $e.', db.getUser().phoneNumber);
      Future.delayed(const Duration(milliseconds: 500)).then((value) {
        rebootWaiting = false;
      });
    }
  }

  Future<void> onClose() async {
    await ble.stopScan();
    await ble.disposeBle();
    await ble.disconnect();
  }
}
