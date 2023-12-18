import 'package:flutter/foundation.dart';
import 'package:realm/realm.dart';

import '../constant/MigrationVersion.dart';
import 'db/EvCall.dart';
import 'db/IdArr.dart';
import 'db/UserData.dart';

class UserDBUtil {
  static final UserDBUtil _dataRequest = UserDBUtil._internal();

  UserDBUtil._internal();

  factory UserDBUtil() {
    return _dataRequest;
  }


  // final userDBCofig = Configuration.local([UserData.schema], schemaVersion: REALM_DB_VERSION);
  //     migrationCallback: ((migration, oldSchemaVersion) {
  //       // Between v1 and v2 we renamed the Person 'age' property to 'yearsSinceBirth'
  //       var oldUserDatas = migration.oldRealm.all('UserData');
  //       for(var oldUser in oldUserDatas) {
  //         var nerUser = migration.findInNewRealm<UserData>(oldUser);
  //
  //         nerUser?.homeEvip = "";
  //         nerUser?.doorEvip = "";
  //       }
  //     })
  // );

  var realmUser = Realm(Configuration.local([UserData.schema], schemaVersion: REALM_DB_VERSION));
  var realmIdArr = Realm(Configuration.local([IdArr.schema], schemaVersion: REALM_DB_VERSION));
  var realmEV = Realm(Configuration.local([EvCall.schema], schemaVersion: REALM_DB_VERSION));

  late RealmResults<UserData> temp1;
  late RealmResults<IdArr> temp2;
  late RealmResults<EvCall> temp3;



  /// Create
  void createUserData(String phoneNumber, String addr, String type, String sDate, String eDate, bool admin, String doorEvip, String homeEvip) {
    realmUser.write(() {
      realmUser.deleteAll<UserData>(); // 기존 데이터 삭제
      // realmUser.add(UserData(phoneNumber, addr , type, sDate, eDate, admin, doorEvip, homeEvip));
      realmUser.add(UserData(phoneNumber, addr , type, sDate, eDate, admin));
    });
    debugPrint("스키마 확인용");
    realmEV.write(() {

      debugPrint("스키마 확인용22");
      realmEV.deleteAll<EvCall>();
      realmEV.add(EvCall(doorEvip, homeEvip));
    });
  }

  void createIDArr(IdArr idArr) {
    realmIdArr.write(() {
      realmIdArr.add(idArr);
    });
  }


  /// Read
  void getDB() {
    temp1 = realmUser.all<UserData>();
    temp2 = realmIdArr.all<IdArr>();
    temp3 = realmEV.all<EvCall>();
  }

  IdArr findCloberByCID(String cid) {
    var finds = temp2.query("cloberid == '$cid'");
    return finds[0];
  }

  UserData getUser() {
    return temp1[0];
  }

  //주소 ccc a동 b호 에서 동,호 숫자만[a,b] 가져오기
  List<String> getDong() {
    String addStr = getUser().addr;
    List<String> addrArr = addStr.split("::");
    debugPrint("Phone Number Check : ${getUser().phoneNumber}");
    debugPrint("Addr Array Check : $addrArr");
    List<String> split = addrArr[0].split(" ");
    String dong = "";
    String ho = "";
    if (split.length - 2 > 0 && split[split.length - 2].contains("동")) {
      dong = split[split.length - 2].replaceAll("동", "");
      ho = split[split.length - 1].replaceAll("호", "");
    }
    debugPrint("Dong Ho Check : $dong, $ho");
    if (dong == "" || ho == "") {
      debugPrint("관리자는 동호가 없어");
    } else {
      if (dong[0] == "0") {
        dong = dong.substring(1);
      }
      if (ho[0] == "0") {
        ho = ho.substring(1);
      }
    }
    return [dong, ho];
  }

  //주소 ccc a동 b호 에서 동,호를 뺀 주소만 가져오기 (ccc)
  String getAddr() {
    String result = "";
    String addStr = getUser().addr;
    bool check = getUser().admin;
    List<String> addrArr = addStr.split("::");
    debugPrint("Phone Number Check : ${getUser().phoneNumber}");
    debugPrint("Addr Array Check : $addrArr");
    List<String> split = addrArr[0].split(" ");
    int length = split.length;
    debugPrint("Addr Check : $split");
    if (!check){
      debugPrint("관리자 아님");
      length -= 2;
    } else {
      debugPrint("관리자 맞음");
      length -= 1;
    }
    for (int i = 0; i < length; i++) {
      debugPrint("Addr Check : ${split[i]}");
      result += split[i];
      debugPrint("i 비교 : $i, $length");
      if (i!=length-1) {
        result += " ";
      }
    }
    return result;
  }

  String getAddr2(String addr, bool admin) {
    String result = "";
    String addStr = addr;
    bool check = admin;
    List<String> addrArr = addStr.split("::");
    // debugPrint("Phone Number Check : ${getUser().phoneNumber}");
    debugPrint("Addr Array Check : $addrArr");
    List<String> split = addrArr[0].split(" ");
    int length = split.length;
    debugPrint("Addr Check : $split");
    if (!check){
      debugPrint("관리자 아님");
      length -= 2;
    } else {
      debugPrint("관리자 맞음");
      length -= 1;
    }
    for (int i = 0; i < length; i++) {
      debugPrint("Addr Check : ${split[i]}");
      result += split[i];
      debugPrint("i 비교 : $i, $length");
      if (i!=length-1) {
        result += " ";
      }
    }
    return result;
  }

  //user가 사용 가능한 출입 Clober list의 첫번째 Clober 가져오기
  String getFirstClober() {
    return temp2[0].cloberid;
  }


  // 관리자 여부
  bool getAdmin() {
    return temp1[0].admin;
  }


  /// Delete
  void deleteDB() {
    realmUser.write(() {
      realmUser.deleteAll<UserData>();
    });
    realmIdArr.write(() {
      realmIdArr.deleteAll<IdArr>();
    });
    realmEV.write(() {
      realmEV.deleteAll<EvCall>();
    });
  }

  /// 기타
  bool isEmpty() {
    return temp1.isEmpty || temp2.isEmpty || temp3.isEmpty;
  }

  bool findCloberByCIDIsEmpty(String cid) {
    var finds = temp2.query("cloberid == '$cid'");
    return finds.isEmpty;
  }

}