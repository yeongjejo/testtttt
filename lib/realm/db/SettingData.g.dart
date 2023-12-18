// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'SettingData.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// ignore_for_file: type=lint
class SettingData extends _SettingData
    with RealmEntity, RealmObjectBase, RealmObject {
  SettingData(
    bool termsOfService,
    int userSetRange,
    bool autoFlowSelectState,
    bool stateOnOff,
    String lastInCloberID,
  ) {
    RealmObjectBase.set(this, 'termsOfService', termsOfService);
    RealmObjectBase.set(this, 'userSetRange', userSetRange);
    RealmObjectBase.set(this, 'autoFlowSelectState', autoFlowSelectState);
    RealmObjectBase.set(this, 'stateOnOff', stateOnOff);
    RealmObjectBase.set(this, 'lastInCloberID', lastInCloberID);
  }

  SettingData._();

  @override
  bool get termsOfService =>
      RealmObjectBase.get<bool>(this, 'termsOfService') as bool;
  @override
  set termsOfService(bool value) =>
      RealmObjectBase.set(this, 'termsOfService', value);

  @override
  int get userSetRange => RealmObjectBase.get<int>(this, 'userSetRange') as int;
  @override
  set userSetRange(int value) =>
      RealmObjectBase.set(this, 'userSetRange', value);

  @override
  bool get autoFlowSelectState =>
      RealmObjectBase.get<bool>(this, 'autoFlowSelectState') as bool;
  @override
  set autoFlowSelectState(bool value) =>
      RealmObjectBase.set(this, 'autoFlowSelectState', value);

  @override
  bool get stateOnOff => RealmObjectBase.get<bool>(this, 'stateOnOff') as bool;
  @override
  set stateOnOff(bool value) => RealmObjectBase.set(this, 'stateOnOff', value);

  @override
  String get lastInCloberID =>
      RealmObjectBase.get<String>(this, 'lastInCloberID') as String;
  @override
  set lastInCloberID(String value) =>
      RealmObjectBase.set(this, 'lastInCloberID', value);

  @override
  Stream<RealmObjectChanges<SettingData>> get changes =>
      RealmObjectBase.getChanges<SettingData>(this);

  @override
  SettingData freeze() => RealmObjectBase.freezeObject<SettingData>(this);

  static SchemaObject get schema => _schema ??= _initSchema();
  static SchemaObject? _schema;
  static SchemaObject _initSchema() {
    RealmObjectBase.registerFactory(SettingData._);
    return const SchemaObject(
        ObjectType.realmObject, SettingData, 'SettingData', [
      SchemaProperty('termsOfService', RealmPropertyType.bool),
      SchemaProperty('userSetRange', RealmPropertyType.int),
      SchemaProperty('autoFlowSelectState', RealmPropertyType.bool),
      SchemaProperty('stateOnOff', RealmPropertyType.bool),
      SchemaProperty('lastInCloberID', RealmPropertyType.string),
    ]);
  }
}
