import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:realm/realm.dart';

import '../constant/YPassURL.dart';
import '../realm/UserDBUtil.dart';
import '../realm/db/IdArr.dart';
import '../realm/db/UserData.dart';
import '../screen/serve/Toast.dart';
import 'HttpPostData.dart';
import 'NetworkState.dart';
import 'StatisticsReporter.dart';
import 'package:http/http.dart' as http;



// 싱글톤
class UserDataRequest {
  static final UserDataRequest _dataRequest = UserDataRequest._internal();

  UserDataRequest._internal();

  factory UserDataRequest() {
    return _dataRequest;
  }

  // realm config 설정
  final configUser = Configuration.local([UserData.schema]);
  final configIdArr = Configuration.local([IdArr.schema]);


  // 유저 데이터 서버 호출 및 DB저장
  Future<bool> setUserData(String phoneNumber) async {

    debugPrint("66666");
    var netState = await checkNetwork();
    StatisticsReporter reporter = StatisticsReporter();

    const Map<String, String> JSON_HEADERS = {
      "content-type": "application/json"
    };

    if (netState != '인터넷 연결 안됨') {
      // 010AAAABBBB를 010-AAAA-BBBB형태로 전환
      String userPhoneNumber = '${phoneNumber.substring(0,3)}-${phoneNumber.substring(3,7)}-${phoneNumber.substring(7)}';

      Map<String, dynamic> sendData = {"data":"{'phone':'$userPhoneNumber'}"}; // 서버에 전송할 파라미터값

      try {
        // 서버에 데이터 요청
        http.Response response = await http.post(
            Uri.parse("https://xphub.xperp.co.kr/_clober/xpclober_api.svc/clober-approval"),
            body: json.encode(sendData),
            headers: JSON_HEADERS
        ).timeout(const Duration(seconds: 10));

        // POST 요청이 성공 했을 경우
        if (response.statusCode == 200) {


          debugPrint("77777");
          // var test = jsonDecode(response.body);
          // var test2 = test.toString().replaceAll('\'', '\"');
          // var test3 = jsonDecode(test2) as Map<String, dynamic>;
          // 위 내용과 jsonData과 동일
          var jsonData = (jsonDecode(jsonDecode(response.body).toString().replaceAll('\'', '"'))) as Map<String, dynamic>;


          if (jsonData['result'] == 0 || jsonData['result'] == '0') {
            CustomToast().showToast('등록된 사용자가 아닙니다. 관리실에 문의해주세요');
            return false;
          }
          var listArr = jsonData['listArr'][0];

          debugPrint("88888");
          // User Realm 불러오기
          UserDBUtil userDB = UserDBUtil();

          userDB.deleteDB(); // 기존 데이터 삭제
          debugPrint("새로운 사이트 주소 : ${listArr['addr']}");
          debugPrint("새로운 사이트 주소 : ${listArr['addr']}");



          String addr = UserDBUtil().getAddr2(listArr['addr'], !(listArr['addr'].toString().contains('동')));

          var ip = await reqSiteAddrIpData(addr);

          userDB.createUserData(phoneNumber, listArr['addr'], listArr['type'], listArr['sDate'], listArr['eDate'], !(listArr['addr'].toString().contains('동')), "$ip/TCPEVCALL", "$ip/TCPEVCALL2"); // 유저 데이터 저장
          //  IdArr (cloberid, userid, pk) 저장
          for (var idArrValue in listArr['idArr']) {
            userDB.createIDArr(IdArr(idArrValue['cloberid'].toString().toLowerCase(), idArrValue['userid'], idArrValue['pk']));
          }

          debugPrint("999999");
          String result;
          try {
            result = await reporter.sendReport(response.body, userPhoneNumber);
            debugPrint("통신 결과 : $result");
          } catch(e) {
            debugPrint("pass log 오류 : $e");
          }


          debugPrint("10101010");
          return true;

        } else {
          debugPrint('Response Status : ${response.statusCode}');
          debugPrint('통신error');
          debugPrint('Response Body : ${response.body}');
          String result;
          try {
            result = await reporter.sendReport(response.body, userPhoneNumber);
            debugPrint("통신 결과 : $result");
          } catch (e) {
            debugPrint("pass log 오류 : $e");
          }
        }
          return false;
      } catch(e) {

        debugPrint("clober-approval 오류: $e");
        return false;
      }

    } else {
      debugPrint('네트워크 연결 실패');
      CustomToast().showToast('인터넷 연결상태를 확인해 주세요.');
      return false;
    }
  }


}