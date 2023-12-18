import 'package:realm/realm.dart';


part 'SettingData.g.dart';

@RealmModel()
class _SettingData {
  late bool termsOfService; // 약관 동의 확인 여부
  late int userSetRange; // 인증 범위 설정
  late bool autoFlowSelectState; // 층 버튼 자동 눌림 설정 상태
  late bool stateOnOff; // 자동문 출입 on off 버튼 상태
  late String lastInCloberID; // 경산에서 집으로 엘베호출시 사용용도
}