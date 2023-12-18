import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:newep/screen/serve/Bar.dart';
import 'package:newep/screen/serve/Toast.dart';
//import 'package:url_launcher/url_launcher.dart';
import '../constant/CustomColor.dart';
import '../constant/YPassURL.dart';
import '../realm/SettingDBUtil.dart';

// 이용 약관 페이지
// 처음 한번만 보여줌
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({Key? key}) : super(key: key);
  static int agreeyNum = 0; // 약관의 동의한 숫자 2이면 모든 약관 수락

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Bar(barSize: 5),
            TOSTopBar(),
            Padding(padding: EdgeInsets.all(20)),
            _Middle(),
          ],
        ),
      ),
    );
  }
}

// 약관 페이지는 뒤로가기시 앱을 종료 해야하므로 따로 구현
class TOSTopBar extends StatefulWidget {
  const TOSTopBar({Key? key}) : super(key: key);

  @override
  State<TOSTopBar> createState() => _TOSTopBarState();
}

class _TOSTopBarState extends State<TOSTopBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: MAIN_BACKGROUND_COLOR,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.7),
            spreadRadius: 0,
            blurRadius: 1.0,
            offset: const Offset(0, 3), // changes position of shadow
          ),
        ],
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(7),
            child: TextButton(
              onPressed: () {
                SystemNavigator.pop();
              },
              child: Image.asset('asset/img/close_btn2.png'),
            ),
          ),
          const Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(0, 0, 80, 0),
              // 이미지 패딩값 7 + 이미지 사이즈 73 = 80
              child: Text('이용 약관',
                  style: TextStyle(
                    fontSize: 18.0,
                  ),
                  textAlign: TextAlign.center),
            ),
          ),
        ],
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
  final Uri privacyTermsOfService = Uri.parse(PRIVACY_TERMS_OF_SERVICE);
  final Uri yPassTermsOfService = Uri.parse(YPASS_TERMS_OF_SERVICE);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
      child: Column(
        children: [
          const Text('서비스 이용 약관에 동의해 주세요.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),),
          const Padding(padding: EdgeInsets.all(10)),
          _TermsOfService(title: '개인정보 제 3자 제공 동의 (필수)', url: privacyTermsOfService),
          _TermsOfService(title: '와이패스 이용 약관 (필수)', url: yPassTermsOfService),
          const Padding(padding: EdgeInsets.all(30)),
          const _AgreeyButton(),
        ],
      ),
    );
  }
}


// 이용 약관들
class _TermsOfService extends StatefulWidget {
  final String title;
  final Uri url;

  const _TermsOfService({Key? key, required this.title, required this.url})
      : super(key: key);

  @override
  State<_TermsOfService> createState() => _TermsOfServiceState();
}

class _TermsOfServiceState extends State<_TermsOfService> {
  bool checkboxValue = false; // 체크상태

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Checkbox(
              value: checkboxValue,
              onChanged: (value) {
                // 이용약관 수락을 하면 +1 취소하면 -1
                setState(() {
                  checkboxValue = value!;
                  value
                      ? TermsOfServiceScreen.agreeyNum += 1
                      : TermsOfServiceScreen.agreeyNum -= 1;
                });
              },
              activeColor: Colors.black,
              // checkColor: Colors.red,
            ),
            Text(widget.title),
          ],
        ),

        TextButton(
          onPressed: (){
            Navigator.of(context).pushNamed('/terms', arguments: widget.url); // 약관 페이지로 이동
          },
          child: const Text('보기'))
      ],
    );
  }
}

// 이용 약관 수락 버튼 (다음 페이지 이동)
class _AgreeyButton extends StatelessWidget {
  const _AgreeyButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: 50,
      child: ElevatedButton(
        onPressed: () {
          // 모든 약관에 동의시 DB저장후 메인페이지로 이동
          // 하나라도 동의 안했을시 약관 동의 안내메세지 전송
          if (TermsOfServiceScreen.agreeyNum == 2) {
            SettingDataUtil().createSettingData(true, 20, false, false, ""); // realm DB에 역관 동의 확인 여부 및 인증 범위 저장
            Navigator.of(context)..pushReplacementNamed('/main')..pushNamed('/updateUser'); // 메인 페이지로 이동
          } else {
            CustomToast().showToast('모든 약관에 동의 해주셔야 됩니다.');
          }
        },
        style: ElevatedButton.styleFrom(
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10))),
          backgroundColor: BAR_COLOR,
        ),
        child: const Text('설정 저장'),
      ),
    );
  }
}
