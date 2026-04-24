import 'result.dart';

typedef Json = Map<String, dynamic>;
typedef AsyncJson = Future<Json>;
typedef AsyncResult<T> = Future<Result<T>>;

extension Helper on Json {
  int get status => this['status'] ?? this['code'] ?? -1;
  dynamic get data => this['data'];
  String? get msg => this['msg'] ?? this['message'];
  bool? get crypt => this['crypt'];
  bool? get isVip => this['isVip'];
}

extension ExInt on int? {
  bool isVip() => this != null && this != 0;
}
