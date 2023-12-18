import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:newep/screen/serve/Bar.dart';
import 'package:newep/screen/serve/Toast.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;

import 'dart:io';

import '../constant/APPInfo.dart';
import '../constant/CustomColor.dart';
import '../constant/YPassURL.dart';
import '../http/NetworkState.dart';
import '../http/StatisticsReporter.dart';
import '../realm/SettingDBUtil.dart';
import '../realm/UserDBUtil.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  bool isAnd = Platform.isAndroid;

  @override
  void initState() {
    super.initState();

    checkPermission(); // 권한 확인
    try {
      // reqSiteAddrIpData();
    } catch (e) {
      debugPrint("사이트 ip, add 요청 에러 : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    Permission.location.isGranted;

    return Scaffold(
      backgroundColor: MAIN_BACKGROUND_COLOR,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Bar(barSize: 10.0),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.7,
              height: MediaQuery.of(context).size.height * 0.2,
              child: Image.asset('asset/img/wifive.png'),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.7,
              height: MediaQuery.of(context).size.height * 0.2,
              child: Image.asset('asset/img/y5logo.png'),
            ),
            const Bar(barSize: 10.0),
          ],
        ),
      ),
    );
  }

  // 권한 설정
  Future<void> checkPermission() async {
    bool rejectPermission = false;
    int andVersion = 0;

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidDeviceInfo = await DeviceInfoPlugin().androidInfo;
      andVersion = androidDeviceInfo.version.sdkInt;
    }

    // 위치 정보
    await Permission.location.request();
    await Permission.location.status.isDenied ? rejectPermission = true : "";
    debugPrint('location$rejectPermission');

    await Permission.locationAlways.request();
    debugPrint('locationAlways : ${await Permission.locationAlways.status.isDenied}');
    await Permission.locationAlways.status.isDenied
        ? rejectPermission = true
        : "";
    debugPrint('locationAlways$rejectPermission');
    //
    // // 블루투스
    if (andVersion < 31 || !isAnd) {
      await Permission.bluetooth.request();
      await Permission.bluetooth.status.isDenied
          ? rejectPermission = true
          : "";
      debugPrint('bluetooth$rejectPermission');

    }

    if (andVersion >= 33  || !isAnd) {
      await Permission.notification.request();
      await Permission.notification.status.isDenied
          ? rejectPermission = true
          : "";
    }

    if (isAnd) {
      await Permission.bluetoothScan.request();
      await Permission.bluetoothScan.status.isDenied
          ? rejectPermission = true
          : "";
      debugPrint('bluetoothScan$rejectPermission');

      await Permission.bluetoothAdvertise.request();
      await Permission.bluetoothAdvertise.status.isDenied
          ? rejectPermission = true
          : "";
      debugPrint('bluetoothScan$rejectPermission');

      await Permission.bluetoothConnect.request();
      await Permission.bluetoothConnect.status.isDenied
          ? rejectPermission = true
          : "";
      debugPrint('bluetoothConnect$rejectPermission');


      debugPrint('bluetoothConnect : ${await Permission.bluetoothConnect.status}');
      if (await Permission.bluetoothConnect.status.isRestricted) {
        print('isRestricted Test');
      }

      await Permission.ignoreBatteryOptimizations.request();
      await Permission.ignoreBatteryOptimizations.status.isDenied
          ? rejectPermission = true
          : "";
      debugPrint('ignoreBatteryOptimizations$rejectPermission');

      await Permission.systemAlertWindow.request();
      await Permission.systemAlertWindow.status.isDenied
          ? rejectPermission = true
          : ""; // 다른 앱 위에 표시
      debugPrint('systemAlertWindow$rejectPermission');
    } else {
      //await Permission.criticalAlerts.request();
      // await Permission.criticalAlerts.status.isDenied
      //     ? rejectPermission = true
      //     : ""; // 다른 앱 위에 표시
      // debugPrint('criticalAlerts : $rejectPermission');
    }

    // 권한 설정 여부 확인
    if (rejectPermission) {
      CustomToast().showToast("모든 권한을 (항상)허용 하셔야 됩니다.");
      Future.delayed(const Duration(seconds: 2), () {
        SystemNavigator.pop();
        exit(0);
      });
    } else {
      // 앱 버전 저장
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      APP_VERSION = packageInfo.version;

      goToMainPage(); // 페이지 이동
    }
  }

  // 페이지 이동
  void goToMainPage() {
    debugPrint('로딩페이지');
    // 페이지 이동
    // 이용 약관 수락한적 있으면 메인페이지로
    // 이용 약관 수락한적 없으면 이용약관 페이지로

    if (SettingDataUtil().isEmpty()) {
      Navigator.pushReplacementNamed(context, '/termsOfService');
    } else {
      UserDBUtil().getDB();
      if (UserDBUtil().isEmpty()) {
        Navigator.of(context)
          ..pushReplacementNamed('/main')
          ..pushNamed('/updateUser');
      } else {
        Navigator.pushReplacementNamed(context, '/main');
      }
    }
  }


}
