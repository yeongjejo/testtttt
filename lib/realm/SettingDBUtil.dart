import 'package:realm/realm.dart';

import '../constant/MigrationVersion.dart';
import 'db/SettingData.dart';


// 싱글톤
class SettingDataUtil {
  static final SettingDataUtil _dataRequest = SettingDataUtil._internal();

  SettingDataUtil._internal();

  factory SettingDataUtil() {
    return _dataRequest;
  }

  final _realm = Realm(Configuration.local([SettingData.schema], schemaVersion: REALM_DB_VERSION)); // DB 설정


  /// Create
  void createSettingData(bool termsOfService, int userSetRange, bool autoFlowState, bool stateOnOff, String lastInCloberID) {
    _realm.write(() {
      _realm.add(SettingData(termsOfService, userSetRange, autoFlowState, stateOnOff, lastInCloberID));
    });
  }


  /// Read
  SettingData getSettingData() {
    return _realm.all<SettingData>()[0];
  }

  bool getTermsOfService() {
    return _realm.all<SettingData>()[0].termsOfService;
  }

  int getUserSetRange() {
    return _realm.all<SettingData>()[0].userSetRange;
  }

  bool getAutoFlowSelectState() {
    return _realm.all<SettingData>()[0].autoFlowSelectState;
  }

  bool getStateOnOff() {
    return _realm.all<SettingData>()[0].stateOnOff;
  }

  String getLastInCloberID() {
    return _realm.all<SettingData>()[0].lastInCloberID;
  }


  /// Update
  void setTermsOfService(bool termsOfService) {
    _realm.write(() => _realm.all<SettingData>()[0].termsOfService = termsOfService);
  }

  void setUserSetRange(int userSetRange) {
    _realm.write(() => _realm.all<SettingData>()[0].userSetRange = userSetRange);
  }

  void setAutoFlowSelectState(bool autoFlowSelectState) {
    _realm.write(() => _realm.all<SettingData>()[0].autoFlowSelectState = autoFlowSelectState);
  }

  void setStateOnOff(bool stateOnOff) {
    _realm.write(() => _realm.all<SettingData>()[0].stateOnOff = stateOnOff);
  }

  void setLastInCloberID(String lastInCloberID) {
    _realm.write(() => _realm.all<SettingData>()[0].lastInCloberID = lastInCloberID);
  }


  /// Delete
  // 아마 사용 할일 없을거같음
  void deleteSettingData() {
    _realm.write(() => _realm.deleteAll<SettingData>());
  }


  /// 기타
  bool isEmpty() {
    return _realm.all<SettingData>().isEmpty;
  }




}