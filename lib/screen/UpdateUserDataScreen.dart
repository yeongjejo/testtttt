import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:newep/screen/serve/Bar.dart';
import 'package:newep/screen/serve/Toast.dart';
import 'package:newep/screen/serve/TopBar.dart';

import '../constant/CustomColor.dart';
import '../constant/Exception.dart';
import '../http/StatisticsReporter.dart';
import '../http/UserDataRequest.dart';
import '../realm/UserDBUtil.dart';
import '../realm/db/IdArr.dart';

// 사용자 정보 수정 페이지
class UpdateUserDataScreen extends StatefulWidget {
  const UpdateUserDataScreen({Key? key}) : super(key: key);

  @override
  State<UpdateUserDataScreen> createState() => _UpdateUserDataScreenState();
}

class _UpdateUserDataScreenState extends State<UpdateUserDataScreen> {

  @override
  void initState() {
    super.initState();
    // daeguTest();
  }

  void daeguTest() {
    UserDBUtil userDB = UserDBUtil();

    userDB.deleteDB(); // 기존 데이터 삭제
    userDB.createUserData("010-0000-0000", "대구 테스트 102동 902호", "0", "2023-09-07 17:15:01", "2023-10-23 17:15:01", !("대구 테스트 102동 902호".toString().contains('동')), "", ""); // 유저 데이터 저장
    //  IdArr (cloberid, userid, pk) 저장
    for (var idArrValue in testIdArr) {
      userDB.createIDArr(IdArr(idArrValue['cloberid'].toString().toLowerCase(), idArrValue['userid']!, idArrValue['pk']!));
    }
    CustomToast().showToast("대구용 DB input 완료.");
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: MAIN_BACKGROUND_COLOR,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Bar(barSize: 10.0),
              TopBar(title: '사용자 정보 수정'), // 상단 타이틀바
              _Middle(),
            ],
          ),
        ),
      ),
    );
  }
}


class _Middle extends StatefulWidget {

  const _Middle({Key? key}) : super(key: key);

  @override
  State<_Middle> createState() => _MiddleState();
}

class _MiddleState extends State<_Middle> {
  TextEditingController textFieldPhoneNumber = TextEditingController(); // 핸드폰번호 입력 텍스트 필드
  TextEditingController authenticatioNumber = TextEditingController(); // 인증번호 입력 텍스트 필드

  FirebaseAuth auth = FirebaseAuth.instance; // 파이어 베이스

  late String phoneNumbe; // 유저 전화번호

  // 인증 번호 여러번 요청 방지 용도
  // true : 인증 문자 요청 가능
  // false : 인증 문자 요청 불가능
  bool waitPhoneAuth = true;
  bool sendSMS = false; // 문자가 전송 되었는지 판단
  late String _verificationId; // 문자 인증 코드

  bool authSuccess = true; // 인증 성공 여부

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          const Text(
            "\"와이패스\" 앱은 핸드폰 번호를 사용하여 서비스를 이용하실 수 있습니다.\n핸드폰 번호는 입주민 확인을 위해서만 사용됩니다.",
            style: TextStyle(fontSize: 20),
          ),
          const Padding(padding: EdgeInsets.all(20)),
          _InputText(
            inputTitle: "전화번호",
            fieldText: textFieldPhoneNumber,
          ),
          SizedBox(
            width: MediaQuery
                .of(context)
                .size
                .width,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                requestAuthNumber(); // 파이어베이스 인증 문자요청
              },
              style: ElevatedButton.styleFrom(
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10))
                ),
                backgroundColor: UPDATE_USER_DATA_BUTTON_COLOR,
              ),
              child: const Text('인증 번호 요청', style: TextStyle(color: Colors.white),),
            ),
          ),
          const Padding(padding: EdgeInsets.all(10)),
          sendSMS ? _InputText(
            inputTitle: "인증번호",
            fieldText: authenticatioNumber,
          ) : const Padding(padding: EdgeInsets.all(1)),
          sendSMS ? SizedBox(
            width: MediaQuery
                .of(context)
                .size
                .width,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                debugPrint(authenticatioNumber.text);
                clickedUpdateInformationButton();
              },
              style: ElevatedButton.styleFrom(
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10))
                ),
                backgroundColor: BAR_COLOR,
              ),
              child: const Text('정보수정', style: TextStyle(color: Colors.white),),
            ),
          ) : const Padding(padding: EdgeInsets.all(1)),
        ],
      ),
    );
  }


  // 파이어베이스 인증 문자요청
  Future<void> requestAuthNumber() async {
    // 문자 요청을 처음 하는 경우
    if (waitPhoneAuth) {
      String num = textFieldPhoneNumber.text.substring(1); // 010AAAABBBB -> 10AAAABBBB
      phoneNumbe = textFieldPhoneNumber.text; // 전화 번호 저장

      // 문자 요청
      await auth.verifyPhoneNumber(
        phoneNumber: "+82 $num", // 인증 요청할 전화번호
        timeout: const Duration(seconds: 119),// 2분 안에 인증 코드를 입력해야됨
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Android only

        },
        // 문지 전송 실패시
        verificationFailed: (FirebaseAuthException e) {
          sendSMSFail(e);
        },
        // 문자 전송 성공시
        codeSent: (String verificationId, int? resendToken) async {
          sendSMSSuccess(verificationId);
        },
        // 타임 아웃 시
        codeAutoRetrievalTimeout: (String verificationId) {
          sendSMSTimeout();
        },
      );
    } else {
      CustomToast().showToast('이미 요청 하였습니다.');
    }
  }

  // 문지 전송 실패시
  sendSMSFail(FirebaseAuthException e) {
    debugPrint('문자 전송 에러 메세지');
    debugPrint(e.toString());
    debugPrint('------------------');

    StatisticsReporter().sendError('$e 문자 전송 실패', phoneNumbe);
    CustomToast().showToast('잘못된 전화번호 입니다.');
    waitPhoneAuth = true;
  }

  // 문자 전송 성공시
  sendSMSSuccess(String verificationId) {
    setState(() {
      _verificationId = verificationId;
      sendSMS = true;
    });
  }

  // 타임 아웃 시
  sendSMSTimeout() {
    CustomToast().showToast('시간이 초과되었습니다. 다시 인증번호를 요청해주세요.');
    waitPhoneAuth = true;
  }

  // 정보 수정 버튼을 클릭시
  void clickedUpdateInformationButton() {
    debugPrint("11111");
    compareVerificationID().then((value1) {
      if (value1) {
        debugPrint("22222");
        // 유저 정보 업데이트
        UserDataRequest().setUserData(phoneNumbe).then((value2) {
          if (value2) {
            debugPrint("33333");
            CustomToast().showToast('정보 수정이 완료되었습니다.');
          }
          debugPrint("44444");
          Navigator.pop(context); // 메인 화면으로 이동
          debugPrint("55555");
        });
      }
    });
  }


  // 인증코드 동일한지 비교
  Future<bool> compareVerificationID() async {
    try {
      // 사용자가 입력한 인증코드와 실제 인증코드가 동일한지 비교
      PhoneAuthCredential phoneAuthCredential = PhoneAuthProvider.credential(verificationId: _verificationId, smsCode: authenticatioNumber.text);
      await auth.signInWithCredential(phoneAuthCredential);

      return true;
    } catch (e) {
      if (e.toString() == INVALID_SMS_CODE) {
        CustomToast().showToast('인증번호가 다릅니다.');
      } else if (e.toString() == EXPIRED_SMS_CODE) {
        CustomToast().showToast('해당 코드가 만료되었습니다. 다시 인증번호를 요청해주세요.');
      } else {
        CustomToast().showToast('잘못된 접근입니다. 다시 시도해주세요.');
      }

      return false;
    }
  }
}


// 텍스트 필드 위젯 함수
class _InputText extends StatelessWidget {
  final String inputTitle; // 텍스트 필드 제목
  final TextEditingController fieldText; // 텍스트 필트에 적은 텍스트 불러오기 용

  const _InputText(
      {Key? key, required this.inputTitle, required this.fieldText})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
      child: TextField(
        decoration: InputDecoration(
            labelText: inputTitle,
            hintText: '$inputTitle를 입력 하세요.',
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10.0)),
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10.0)),
            )),
        keyboardType: TextInputType.number,
        controller: fieldText,
      ),
    );
  }
}


var testIdArr = [
  {
    "userid":"0101010b356b",
    "pk":"Q7dcUMxkz1",
    "cloberid":"01010303"
  },
  {
    "userid":"0101010b3c13",
    "pk":"CnQ1RlSkVN",
    "cloberid":"01010304"
  },
  {
    "userid":"0101010b4238",
    "pk":"ZWqy2kR0oe",
    "cloberid":"01010305"
  },
  {
    "userid":"0101010b485e",
    "pk":"EfqK92J3hs",
    "cloberid":"01010306"
  },
  {
    "userid":"0101010b4f05",
    "pk":"pEDx7NGLfT",
    "cloberid":"01010307"
  },
  {
    "userid":"0101010b552b",
    "pk":"OpQiGj2efd",
    "cloberid":"01010308"
  },
  {
    "userid":"0101010b5b51",
    "pk":"72cz8PfVDW",
    "cloberid":"01010309"
  },
  {
    "userid":"0101010b6177",
    "pk":"Hut46PqVBs",
    "cloberid":"0101030a"
  },
  {
    "userid":"0101010b681e",
    "pk":"kK32RsEeGU",
    "cloberid":"0101030b"
  },
  {
    "userid":"0101010b746a",
    "pk":"DZy9f2pe8F",
    "cloberid":"0101030d"
  },
  {
    "userid":"0101010b7b11",
    "pk":"Aen4WFcfsh",
    "cloberid":"0101030e"
  },
  {
    "userid":"0101010c0237",
    "pk":"Wd1pXEmtb6",
    "cloberid":"0101030f"
  },
  {
    "userid":"0101010b6e44",
    "pk":"IZ83Eu5NKt",
    "cloberid":"0101030c"
  },
  {
    "userid":"0101010c085d",
    "pk":"RMp651VtQK",
    "cloberid":"01010310"
  },
  {
    "userid":"0101010c0f04",
    "pk":"ZcR7Og8zne",
    "cloberid":"01010311"
  },
  {
    "userid":"0101010c152a",
    "pk":"is52qAHKcv",
    "cloberid":"01010312"
  },
  {
    "userid":"0101010c1b50",
    "pk":"beVKRoLtnH",
    "cloberid":"01010313"
  },
  {
    "userid":"0101010c2176",
    "pk":"gpOYz5WHTn",
    "cloberid":"01010314"
  },
  {
    "userid":"0101010c281d",
    "pk":"VQFuixHP6S",
    "cloberid":"01010315"
  },
  {
    "userid":"0101010c2e43",
    "pk":"ie5M9DaFJg",
    "cloberid":"01010316"
  },
  {
    "userid":"0101010c3469",
    "pk":"impJSqj29R",
    "cloberid":"01010317"
  },
  {
    "userid":"0101010c3b10",
    "pk":"PIGHVNMtBC",
    "cloberid":"01010318"
  },
  {
    "userid":"0101010c4136",
    "pk":"DJ2NwhxrSK",
    "cloberid":"01010319"
  },
  {
    "userid":"0101010c475c",
    "pk":"XEJ7hrOksC",
    "cloberid":"0101031a"
  },
  {
    "userid":"0101010c4e03",
    "pk":"5wsJtXz8nU",
    "cloberid":"0101031b"
  },{
    "userid":"0101010c5429",
    "pk":"19eEQsH4CF",
    "cloberid":"0101031c"
  },
  {
    "userid":"0101010c5a4f",
    "pk":"nB4IA1Kv0X",
    "cloberid":"0101031d"
  }
];