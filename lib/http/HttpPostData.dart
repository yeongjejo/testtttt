import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:newep/http/NetworkState.dart' as ns;

import '../constant/APPInfo.dart';
import '../constant/YPassURL.dart';
import '../realm/SettingDBUtil.dart';
import '../realm/UserDBUtil.dart';
import 'HttpType.dart';
import 'NetworkState.dart';
import 'StatisticsReporter.dart';

var client = HttpClient();
StatisticsReporter reporter = StatisticsReporter();
//url 확인 필요 일단 긁어옴
String url = YPASS_EZS_URL;

late int httpType;

late final int data;
late String netState;

//inoutUser = 1
Future<String> cloberPass(int pass, String cid, String maxRssi) async {
  netState = await ns.checkNetwork();

  if (netState != '인터넷 연결 안됨') {
    httpType = HttpType.tempUser;
    DeviceInfoPlugin device = DeviceInfoPlugin();
    UserDBUtil db = UserDBUtil();
    SettingDataUtil set = SettingDataUtil();
    var find = db.findCloberByCID(cid);

    String userid = find.userid;
    List listUserid = [userid.substring(0,2), userid.substring(2,4), userid.substring(4,6), userid.substring(6,8), userid.substring(8,10), userid.substring(10,12)];
    List convetedList = listUserid.map((number) => int.parse(number, radix: 16).toString()).toList();
    String isAnd = "0";

    String model = '휴대폰 기종';
    String brand = '확인중 휴대폰 브랜드 예상';
    if (Platform.isIOS) {
      isAnd = "1";
      IosDeviceInfo iosInfo = await device.iosInfo;
      model = iosInfo.model;
      brand = "Apple";
    } else {
      AndroidDeviceInfo andInfo = await device.androidInfo;
      model = andInfo.model;
      brand = andInfo.brand;
    }
    //평균 RSSI = BLE 스캔시 얻은 max RSSI 값
    //마지막 0은 뭔지 확인 필요
    String rssi = "$maxRssi,$model,${-75.5-set.getUserSetRange()},$isAnd";
    String setRssi = "${-75.5-set.getUserSetRange()}";
    String conUserId = "";
    for (String i in convetedList) {
      conUserId += "$i,";
    }
    conUserId = conUserId.substring(0,conUserId.length-1);

    //type은 pass 성공하면 0으로
    //kind도 확인 예정 And, iOS 구분 예상
    debugPrint(APP_VERSION);
    try {
      http.Response response = await http.post(
          Uri.parse(YPASS_POST_TEST),
          body: <String, String>{
            "id": conUserId,
            "type": (pass - 1).toString(),
            "rssi": rssi,
            "setRssi": setRssi,
            "phone": model,
            "kind": isAnd,
            "brand": brand,
            "version": APP_VERSION
          }
      ).timeout(const Duration(seconds: 1));
      if (response.statusCode == 200) {
        String result;
        if (response.body == "") {
          result = "통신 성공";
        } else {
          result = response.body;
        }
        return result;
      } else {
        return "통신error : ${response.body}, ${response.statusCode}";
      }
    } on TimeoutException catch (e) {
      return "네트워크 연결 실패 : $e";
    }
  } else {
    return "네트워크 연결 실패";
  }
}
/*
//tempUser = 2
Future<String> setTempUser(String vphone, String vaddr, String sDate, String eDate) async {
  //유저 등록 확인 필요


  netState = await ns.checkNetwork();

  if (netState != '인터넷 연결 안됨') {
    httpType = HttpType.tempUser;
    String phoneNumber = 'userData 번호가져와야함';

    http.Response response = await http.post(
        Uri.parse("$url/put-visitguest"),
        body: <String, String> {
          "data" : <String, String> {
            "phone" : phoneNumber,
            "v_phone" : vphone,
            "v_addr" : vaddr,
            "sDate" : sDate,
            "eDate" : eDate
          }.toString()
        }
    ).timeout(const Duration(seconds: 1));
    if (response.statusCode == 200) {
      return response.body;
    } else {
      return "통신error";
    }
  } else {
    return "네트워크 연결 실패";
  }
}

//getLicense = 3
Future<String> userLicense(int type, int scanType) {
  return Future.value("false");
}*/

//evHome = 5
//집에서 호출
Future<String> homeEvCall(String phoneNumber, String dong, String ho) async {
  netState = await ns.checkNetwork();

  UserDBUtil db = UserDBUtil();
  if (netState != '인터넷 연결 안됨') {
    String? url = "";
    httpType = HttpType.evHome;

    String userAddr = db.getAddr();
    url = UserDBUtil().temp3[0].homeEvip;
    debugPrint("URL Check : $url");
    debugPrint("Phone Number Check : $phoneNumber");
    debugPrint("Addr Check : $dong, $ho");
    try {
      final response = await http.get(Uri.parse("$url/$dong/$ho")).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        var temp = jsonDecode(response.body);
        debugPrint("Response body 확인 : $temp");
        debugPrint("Response String 확인 : ${temp.runtimeType == String}");
        if (temp.runtimeType != String && temp["result"] == 0) {
          debugPrint("실패");
          return temp["message"];
        } else {
          debugPrint("성공");
          return response.body;
        }
      } else {
        debugPrint("통신 확인");
        //log 남기기 통신
        String result;
        result = await reporter.sendError("승강기 통신 실패", phoneNumber);
        return "통신error : $result";
      }
    } on TimeoutException catch (_) {
      debugPrint("실패");
      return "타임아웃: 서버(wifive) 연결에 실패했습니다.";
    }
  } else {
    return "네트워크 연결 실패";
  }
}

//밖에서 호출
Future<String> evCall(String cid, String phoneNumber) async {
  netState = await ns.checkNetwork();

  UserDBUtil db = UserDBUtil();
  if (netState != '인터넷 연결 안됨') {
    String? url = "";

    String userAddr = db.getAddr();
    // await reqSiteAddrIpData();
    debugPrint("Http Addr Check : $userAddr");
    // debugPrint("Http Addr  : $ADDRESS_LIST");
    url = UserDBUtil().temp3[0].doorEvip;
    debugPrint("evURLsssss : $url");
    // debugPrint("URL : $url");
    try {
      final response = await http.get(Uri.parse("$url/$cid")).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        var temp = jsonDecode(response.body);
        debugPrint("Response body 확인 : $temp");
        debugPrint("Response String 확인 : ${temp.runtimeType == String}");
        if (temp.runtimeType != String && temp["result"] == 0) {
          debugPrint("실패");
          return temp["message"];
        } else {
          debugPrint("성공");
          return response.body;
        }
      } else {
        //log 남기기 통신
        String result;
        result = await reporter.sendError("승강기 통신 실패", phoneNumber);
        return "통신error : $result";
      }
    } on TimeoutException catch (_) {
      debugPrint("실패");
      return "타임아웃: 서버(wifive) 연결에 실패했습니다.";
    }
  } else {
    return "네트워크 연결 실패";
  }
}

Future<String> evCallGyeongSan(String phoneNumber, bool isInward, String cloberId, String? ho) async {
  netState = await ns.checkNetwork();

  if (netState != '인터넷 연결 안됨') {
    String url = "";
    httpType = HttpType.evHome;

    UserDBUtil userDB = UserDBUtil();
    SettingDataUtil db = SettingDataUtil();
    String inClober = db.getLastInCloberID();
    if (inClober == "") {
      inClober = userDB.getFirstClober();
    }
    if (isInward) {
      url = YPASS_GYEONGSAN_EV;
      //ho = null이면 ""으로
      ho ??= "";
      try {
        final response =
        await http.get(Uri.parse("$url/$inClober/$cloberId/$ho"));
        if (response.statusCode == 200) {
          return response.body;
        } else {
          //log 남기기 통신
          String result;
          result = await reporter.sendError("승강기 통신 실패", phoneNumber);
          return "통신error : $result";
        }
      } on TimeoutException catch (e) {
        return "통신error : $e";
      }
    } else {
      url = YPASS_GYEONGSAN_HOME;
      try {
        final response =
        await http.get(Uri.parse("$url/$inClober/$cloberId"));
        if (response.statusCode == 200) {
          return response.body;
        } else {
          //log 남기기 통신
          String result;
          result = await reporter.sendError("승강기 통신 실패", phoneNumber);
          return "통신error : $result";
        }
      } on TimeoutException catch (e) {
        return "통신error : $e";
      }
    }
  } else {
    return "네트워크 연결 실패";
  }
}



Future<String> reqSiteAddrIpData(String addr) async {
  String ip = "";
  if (await checkNetwork() == "인터넷 연결 안됨") {
    return "false";
  }

  Map<String, dynamic> sendData = {"igisaddr": addr};

  http.Response response = await http.post(
      Uri.parse("https://wifivecloud.co.kr:8000/find-parking"),
      body: json.encode(sendData),
      headers: {"content-type": "application/json"}
  ).timeout(const Duration(seconds: 10));

  debugPrint("req결과 : ${jsonDecode(response.body)}");
  if (response.statusCode == 200) {


    for(var data in jsonDecode(response.body)) {
      try {
        ip = data["ip"];

        // ADDRESS_LIST[addr] = "$ip/TCPEVCALL";
        // HOME_ADDRESS_LIST[addr] = "$ip/TCPEVCALL2";


      } catch (e) {
        if(!UserDBUtil().isEmpty()) {
          StatisticsReporter().sendError('DB에 addr이나 ip가 잘못된 정보가 들어있음', UserDBUtil().getUser().phoneNumber);
        } else {
          StatisticsReporter().sendError('DB에 addr이나 ip가 잘못된 정보가 들어있음', '010-0000-0000');
        }
      }

    }
  } else {
    debugPrint("요성 실패 : ${response.body}");
  }


  return ip;


}