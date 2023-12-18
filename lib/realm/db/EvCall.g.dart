// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'EvCall.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// ignore_for_file: type=lint
class EvCall extends _EvCall with RealmEntity, RealmObjectBase, RealmObject {
  EvCall(
    String doorEvip,
    String homeEvip,
  ) {
    RealmObjectBase.set(this, 'doorEvip', doorEvip);
    RealmObjectBase.set(this, 'homeEvip', homeEvip);
  }

  EvCall._();

  @override
  String get doorEvip =>
      RealmObjectBase.get<String>(this, 'doorEvip') as String;
  @override
  set doorEvip(String value) => RealmObjectBase.set(this, 'doorEvip', value);

  @override
  String get homeEvip =>
      RealmObjectBase.get<String>(this, 'homeEvip') as String;
  @override
  set homeEvip(String value) => RealmObjectBase.set(this, 'homeEvip', value);

  @override
  Stream<RealmObjectChanges<EvCall>> get changes =>
      RealmObjectBase.getChanges<EvCall>(this);

  @override
  EvCall freeze() => RealmObjectBase.freezeObject<EvCall>(this);

  static SchemaObject get schema => _schema ??= _initSchema();
  static SchemaObject? _schema;
  static SchemaObject _initSchema() {
    RealmObjectBase.registerFactory(EvCall._);
    return const SchemaObject(ObjectType.realmObject, EvCall, 'EvCall', [
      SchemaProperty('doorEvip', RealmPropertyType.string),
      SchemaProperty('homeEvip', RealmPropertyType.string),
    ]);
  }
}
