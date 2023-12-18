import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:newep/screen/serve/Bar.dart';
import 'package:newep/screen/serve/LinePadding.dart';
import 'package:newep/screen/serve/TopBar.dart';
import '../constant/CustomColor.dart';
import '../realm/SettingDBUtil.dart';
import '../realm/UserDBUtil.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MAIN_BACKGROUND_COLOR,
      body: SafeArea(
        child: Column(
          children: [
            const Bar(barSize: 10.0),
            const TopBar(title: '설정'), // 상단 타이틀바
            _Middle(),

          ],
        ),
      ),
    );
  }
}

class _Middle extends StatefulWidget {
  double stateNumber = SettingDataUtil().getUserSetRange().toDouble();
  bool isGyeongSan = UserDBUtil().getUser().addr.contains('경산');

  _Middle({Key? key}) : super(key: key);

  @override
  State<_Middle> createState() => _MiddleState();
}

class _MiddleState extends State<_Middle> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '인증범위 설정',
            style: TextStyle(
              fontSize: 20,
            ),
          ),
          const LinePadding(value: 10),
          Text(
            '현재 설정된 단계는 : ${widget.stateNumber}',
            style: const TextStyle(color: UPDATE_USER_DATA_BUTTON_COLOR),
          ),
          const LinePadding(value: 20),
          Row(
            children: [
              const Text('0'),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    // trackHeight: 10.0,

                    activeTrackColor: BAR_COLOR,
                    inactiveTrackColor: Colors.black38,
                    thumbColor: Colors.red,
                    activeTickMarkColor: BAR_COLOR,
                    inactiveTickMarkColor: Colors.white,
                  ),
                  child: Slider(
                    min: 0.0,
                    max: 20.0,
                    value: widget.stateNumber,
                    divisions: 20,
                    label: '${widget.stateNumber}',
                    onChanged: (value) {
                      setState(() {
                        widget.stateNumber = value;
                      });
                    },
                  ),
                ),
              ),
              const Text('20')
            ],
          ),
          const LinePadding(value: 10),
          const Text(
            '인증단계가 높을수록 멀리서 인증됩니다.',
            style: TextStyle(color: UPDATE_USER_DATA_BUTTON_COLOR),
          ),
          const LinePadding(value: 20),

          widget.isGyeongSan ? const AutoFlowButton() : const LinePadding(value: 5),// 경산 층 버튼용

          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                SettingDataUtil().setUserSetRange(widget.stateNumber.toInt());
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10))),
                backgroundColor: BAR_COLOR,
              ),
              child: const Text('설정 저장', style: TextStyle(color: Colors.white),),
            ),
          ),
        ],
      ),
    );
  }
}


// 경산 전용 층 버튼 자동 눌임
class AutoFlowButton extends StatefulWidget {

  const AutoFlowButton({Key? key}) : super(key: key);

  @override
  State<AutoFlowButton> createState() => _AutoFlowButtonState();
}

class _AutoFlowButtonState extends State<AutoFlowButton> {
  SettingDataUtil settingData = SettingDataUtil();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('층 버튼 자동 눌림', style: TextStyle(fontSize: 20)),
            FlutterSwitch(
              width: 60.0,
              height: 35.0,
              valueFontSize: 10.0,
              toggleSize: 25.0,
              value: settingData.getAutoFlowSelectState(),
              borderRadius: 30.0,
              showOnOff: true,
              activeColor: BAR_COLOR,
              activeTextColor: TRANSPARENT_COLOR,
              inactiveTextColor: TRANSPARENT_COLOR,
              onToggle: (value) {
                setState(() {
                  if (!SettingDataUtil().isEmpty()) {
                    settingData.setAutoFlowSelectState(value);
                  }
                  // if (settingData)
                });
              },
            ),

          ],
        ),
        const LinePadding(value: 5),
        const Text('엘리베이터 탑승 시, 현재 거주층 또는 마지막으로 출입했던 층을 자동으로 눌러주는 기능입니다.',
          style: TextStyle(color: UPDATE_USER_DATA_BUTTON_COLOR),),
        const LinePadding(value: 3),
        const Text(' * 이 기능은 시범적으로 제공하는 기능으로 안정화 될때까지\n    이용 하실 입주민분만 스위치 on하여 사용해주시기 바랍니다.',
          style: TextStyle(color: UPDATE_USER_DATA_BUTTON_COLOR, fontSize: 10)),
        const LinePadding(value: 20),
      ],
    );
  }
}
