part of '../repo.dart';

mixin _Home on _BaseAppRepo implements HomeDomain {

  @override
  AsyncJson reqAdClickCount({int? id, int? type}) =>
      _homeService.reqAdClickCount(id: id ?? 0, type: type ?? 0);

}