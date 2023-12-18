import 'package:realm/realm.dart';

part 'EvCall.g.dart';

@RealmModel()
class _EvCall {
  late String doorEvip;     // 출입문 엘레베이터 호출
  late String homeEvip;     // 집 엘레베이터 호출
}