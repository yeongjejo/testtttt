import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:newep/http/NetworkState.dart' as ns;

import '../realm/UserDBUtil.dart';

class StatisticsReporter {
  var client = HttpClient();

  String reportUrl = "http://211.46.227.157:4001/userLog";
  String errorUrl = "http://211.46.227.157:4001/ypasserrorLog";
  late String netState;

  Future<String> sendReport(String resBody, String phoneNumber) async {
    netState = await ns.checkNetwork();

    if (netState != '인터넷 연결 안됨') {

      var jsonData = (jsonDecode(jsonDecode(resBody).toString().replaceAll('\'', '"'))) as Map<String, dynamic>;
      var listArr = jsonData['listArr'][0];
      String brand;
      if (Platform.isIOS) {
        brand = "Apple";
      } else {
        brand = "android";
      }
      try {
        http.Response response = await http.post(
            Uri.parse(reportUrl),
            body: <String, String>{
              "phoneNumber": phoneNumber,
              "num": listArr['num'],
              "addr": listArr['addr'],
              "type": listArr['type'],
              "sDate": listArr['sDate'],
              "eDate": listArr['eDate'],
              "idArr": jsonEncode(listArr['idArr']).toString(),
              "brand": brand
            }
        ).timeout(const Duration(seconds: 1));
        if (response.statusCode == 200) {
          return response.body;
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

  Future<String> sendError(String errorMessage, String phoneNumber) async {
    netState = await ns.checkNetwork();

    if (netState != '인터넷 연결 안됨') {
      UserDBUtil db = UserDBUtil();

      String userAddr = db.getUser().addr;

      String brand = '휴대폰 브랜드';
      if (Platform.isIOS) {
        brand = "Apple";
      } else {
        brand = "android";
      }

      try {
        http.Response response = await http.post(
            Uri.parse(errorUrl),
            body: <String, String>{
              "brand": brand,
              "phoneNumber": phoneNumber,
              "addr": userAddr,
              "errorlog": errorMessage
            }
        ).timeout(const Duration(seconds: 1));
        if (response.statusCode == 200) {
          return response.body;
        } else {
          return "통신error";
        }
      } on TimeoutException catch (e) {
        return "네트워크 연결 실패 : $e";
      }
    } else {
      return "네트워크 연결 실패";
    }
  }
}