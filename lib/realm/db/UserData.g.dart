// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'UserData.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// ignore_for_file: type=lint
class UserData extends _UserData
    with RealmEntity, RealmObjectBase, RealmObject {
  UserData(
    String phoneNumber,
    String addr,
    String type,
    String sDate,
    String eDate,
    bool admin,
  ) {
    RealmObjectBase.set(this, 'phoneNumber', phoneNumber);
    RealmObjectBase.set(this, 'addr', addr);
    RealmObjectBase.set(this, 'type', type);
    RealmObjectBase.set(this, 'sDate', sDate);
    RealmObjectBase.set(this, 'eDate', eDate);
    RealmObjectBase.set(this, 'admin', admin);
  }

  UserData._();

  @override
  String get phoneNumber =>
      RealmObjectBase.get<String>(this, 'phoneNumber') as String;
  @override
  set phoneNumber(String value) =>
      RealmObjectBase.set(this, 'phoneNumber', value);

  @override
  String get addr => RealmObjectBase.get<String>(this, 'addr') as String;
  @override
  set addr(String value) => RealmObjectBase.set(this, 'addr', value);

  @override
  String get type => RealmObjectBase.get<String>(this, 'type') as String;
  @override
  set type(String value) => RealmObjectBase.set(this, 'type', value);

  @override
  String get sDate => RealmObjectBase.get<String>(this, 'sDate') as String;
  @override
  set sDate(String value) => RealmObjectBase.set(this, 'sDate', value);

  @override
  String get eDate => RealmObjectBase.get<String>(this, 'eDate') as String;
  @override
  set eDate(String value) => RealmObjectBase.set(this, 'eDate', value);

  @override
  bool get admin => RealmObjectBase.get<bool>(this, 'admin') as bool;
  @override
  set admin(bool value) => RealmObjectBase.set(this, 'admin', value);

  @override
  Stream<RealmObjectChanges<UserData>> get changes =>
      RealmObjectBase.getChanges<UserData>(this);

  @override
  UserData freeze() => RealmObjectBase.freezeObject<UserData>(this);

  static SchemaObject get schema => _schema ??= _initSchema();
  static SchemaObject? _schema;
  static SchemaObject _initSchema() {
    RealmObjectBase.registerFactory(UserData._);
    return const SchemaObject(ObjectType.realmObject, UserData, 'UserData', [
      SchemaProperty('phoneNumber', RealmPropertyType.string),
      SchemaProperty('addr', RealmPropertyType.string),
      SchemaProperty('type', RealmPropertyType.string),
      SchemaProperty('sDate', RealmPropertyType.string),
      SchemaProperty('eDate', RealmPropertyType.string),
      SchemaProperty('admin', RealmPropertyType.bool),
    ]);
  }
}
