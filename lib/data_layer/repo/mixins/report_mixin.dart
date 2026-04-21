part of '../repo.dart';

mixin _Report on _BaseAppRepo implements ReportDomain {
  @override
  AsyncResult getEncryptedConfig() =>
      _reportService
      .getEncryptedConfig()
      .deserialize()
      .guard;
}