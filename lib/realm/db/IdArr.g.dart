// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'IdArr.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// ignore_for_file: type=lint
class IdArr extends _IdArr with RealmEntity, RealmObjectBase, RealmObject {
  IdArr(
    String cloberid,
    String userid,
    String pk,
  ) {
    RealmObjectBase.set(this, 'cloberid', cloberid);
    RealmObjectBase.set(this, 'userid', userid);
    RealmObjectBase.set(this, 'pk', pk);
  }

  IdArr._();

  @override
  String get cloberid =>
      RealmObjectBase.get<String>(this, 'cloberid') as String;
  @override
  set cloberid(String value) => RealmObjectBase.set(this, 'cloberid', value);

  @override
  String get userid => RealmObjectBase.get<String>(this, 'userid') as String;
  @override
  set userid(String value) => RealmObjectBase.set(this, 'userid', value);

  @override
  String get pk => RealmObjectBase.get<String>(this, 'pk') as String;
  @override
  set pk(String value) => RealmObjectBase.set(this, 'pk', value);

  @override
  Stream<RealmObjectChanges<IdArr>> get changes =>
      RealmObjectBase.getChanges<IdArr>(this);

  @override
  IdArr freeze() => RealmObjectBase.freezeObject<IdArr>(this);

  static SchemaObject get schema => _schema ??= _initSchema();
  static SchemaObject? _schema;
  static SchemaObject _initSchema() {
    RealmObjectBase.registerFactory(IdArr._);
    return const SchemaObject(ObjectType.realmObject, IdArr, 'IdArr', [
      SchemaProperty('cloberid', RealmPropertyType.string),
      SchemaProperty('userid', RealmPropertyType.string),
      SchemaProperty('pk', RealmPropertyType.string),
    ]);
  }
}
