import 'package:realm/realm.dart';

part 'UserData.g.dart';

@RealmModel()
class _UserData {
  late String phoneNumber;  // 핸드폰 번호
  late String addr;         // 집주소
  late String type;         // 0:입주자, 1:방문자
  late String sDate;        // 방문 가능 시작 시간
  late String eDate;        // 방문 가능 종료 시간
  late bool admin;          // 관리자 체크
  // late String doorEvip;     // 출입문 엘레베이터 호출
  // late String homeEvip;     // 집 엘레베이터 호출
}

