class AdModel {
  AdModel({
    this.id,
    this.title,
    this.description,
    this.imgUrl,
    this.url,
    this.position,
    this.androidDownUrl,
    this.iosDownUrl,
    this.type,
    this.status,
    this.oauthType,
    this.mvM3U8,
    this.channel,
    this.createdAt,
    this.subTitle,
    this.adType,
    this.adSlotName,
    this.advertiseCode,
    this.advertiseLocationCode,
  });

  final int? id;
  final String? title;
  final String? description;
  final String? imgUrl;
  final String? url;
  final int? position;
  final String? androidDownUrl;
  final String? iosDownUrl;
  final int? type;
  final int? status;
  final int? oauthType;
  final String? mvM3U8;
  final String? channel;
  final String? createdAt;
  final String? subTitle;

  final String? adType;
  final String? adSlotName;
  final String? advertiseCode;
  final String? advertiseLocationCode;

  factory AdModel.fromJson(Map<String, dynamic> json) => AdModel(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        imgUrl: json['img_url'],
        url: json['url'],
        position: json['position'],
        androidDownUrl: json['android_down_url'],
        iosDownUrl: json['ios_down_url'],
        type: json['type'],
        status: json['status'],
        oauthType: json['oauth_type'],
        mvM3U8: json['mv_m3u8'],
        channel: json['channel'],
        createdAt: json['created_at'].toString(),
        subTitle: json['sub_title'],
        adType: json['ad_type']?.toString(),
        adSlotName: json['ad_slot_name'] as String?,
        advertiseCode: json['advertise_code'] as String?,
        advertiseLocationCode: json['advertise_location_code'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'img_url': imgUrl,
        'url': url,
        'position': position,
        'android_down_url': androidDownUrl,
        'ios_down_url': iosDownUrl,
        'type': type,
        'status': status,
        'oauth_type': oauthType,
        'mv_m3u8': mvM3U8,
        'channel': channel,
        'created_at': createdAt,
        'sub_title': subTitle,
        'ad_type': adType,
        'ad_slot_name': adSlotName,
        'advertise_code': advertiseCode,
        'advertise_location_code': advertiseLocationCode,
      };
}

class SplashAd {
  const SplashAd({
    required this.id,
    required this.imageUrl,
    this.actionUrl,
    required this.duration,
  });

  final int id;
  final String imageUrl;
  final String? actionUrl;
  final int duration;

  factory SplashAd.fromJson(Map<String, dynamic> json) => SplashAd(
        id: int.tryParse('${json['id'] ?? 0}') ?? 0,
        imageUrl: '${json['image_url'] ?? ''}',
        actionUrl: json['action_url']?.toString(),
        duration: int.tryParse('${json['duration'] ?? 2}') ?? 2,
      );
}
