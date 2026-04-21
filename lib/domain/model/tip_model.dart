class TipModel {
  final int? id;
  final String? title;
  final String? type;
  final String? config;
  final String? router;
  final String? urlStr;
  final int? redirectType;

  TipModel({
    this.id,
    this.title,
    this.type,
    this.config,
    this.router,
    this.urlStr,
    this.redirectType,
  });

  factory TipModel.fromJson(Map<String, dynamic> json) => TipModel(
        id: json['id'],
        title: json['title'],
        type: json['type'],
        config: json['config'],
        router: json['router'],
        urlStr: json['url_str'],
        redirectType: json['redirect_type'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type,
        'config': config,
        'router': router,
        'url_str': urlStr,
        'redirect_type': redirectType,
      };
}
