class VlogModel {
  final int? id;
  final String? title;
  final int? aff;
  final String? coverVertical;
  final String? coverHorizontal;
  final String? tags;
  final int? isFree;
  final int? coins;
  final int? playCt;
  final int? countComment;
  int? countLike;
  int? isLike;
  final int? duration;
  String? source_240;
  final int? mvType;
  final String? sourceOriginStr;
  final List<dynamic>? tagList;
  final int? isPay;
  final int? discount;
  final int? discountCoins;
  final bool? isPackage;
  final String? previewUrl;
  int? isFavorite;
  int? favorites;

  //广告数据
  final String? description;
  final String? imgUrl;
  final int? type;
  final String? router;
  final String? urlStr;
  final String? linkUrl;
  final String? url;
  final String? resourceUrl;
  final int? redirectType;
  final int? reportId;
  final int? reportType;

  final String? videoTypeId;
  final String? videoTypeName;
  final String? videoContentType;
  final String? recommendTraceId;
  final String? videoTagKey;
  final String? videoTagName;
  final String mediaId;

  VlogModel({
    this.id,
    this.title,
    this.aff,
    this.coverVertical,
    this.coverHorizontal,
    this.tags,
    this.isFree,
    this.coins,
    this.playCt,
    this.countComment,
    this.countLike,
    this.isLike,
    this.favorites,
    this.isFavorite,
    this.duration,
    this.source_240,
    this.mvType,
    this.sourceOriginStr,
    this.tagList,
    this.isPay,
    this.discount,
    this.discountCoins,
    this.isPackage,
    this.previewUrl,
    this.description,
    this.imgUrl,
    this.type,
    this.router,
    this.urlStr,
    this.linkUrl,
    this.url,
    this.resourceUrl,
    this.redirectType,
    this.reportType,
    this.reportId,
    this.videoTypeId,
    this.videoTypeName,
    this.videoContentType,
    this.recommendTraceId,
    this.videoTagKey,
    this.videoTagName,
    this.mediaId = '',
  });

  factory VlogModel.fromJson(Map<String, dynamic> json) => VlogModel(
        id: json['id'],
        title: json['title'],
        aff: json['aff'],
        coverVertical: json['cover_vertical'],
        coverHorizontal: json['cover_horizontal'],
        tags: json['tags'],
        isFree: json['isfree'],
        coins: json['coins'],
        playCt: json['play_ct'],
        countComment: json['count_comment'],
        countLike: json['count_like'],
        isLike: json['is_like'],
        favorites: json['favorites'],
        isFavorite: json['is_favorite'],
        duration: json['duration'],
        source_240: json['source_240'],
        mvType: json['mv_type'],
        sourceOriginStr: json['source_origin_str'],
        tagList: json['tag_list'],
        isPay: json['is_pay'],
        discount: json['discount'],
        discountCoins: json['discount_coins'],
        isPackage: json['is_package'],
        previewUrl: json['preview_url'],
        description: json['description'],
        imgUrl: json['img_url'],
        type: json['type'],
        router: json['router'],
        urlStr: json['url_str'],
        linkUrl: json['link_url'],
        url: json['url'],
        resourceUrl: json['resource_url'],
        redirectType: json['redirect_type'],
        reportId: json['report_id'],
        reportType: json['report_type'],
        videoTypeId: json['video_type_id']?.toString() ?? '',
        videoTypeName: json['video_type_name'] ?? '',
        videoContentType: json['video_content_type'],
        recommendTraceId: json['recommend_trace_id'],
        videoTagKey: json['video_tag_key'],
        videoTagName: json['video_tag_name'],
        mediaId: json['media_id'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'aff': aff,
        'cover_vertical': coverVertical,
        'cover_horizontal': coverHorizontal,
        'tags': tags,
        'isfree': isFree,
        'coins': coins,
        'play_ct': playCt,
        'count_like': countLike,
        'is_like': isLike,
        'favorites': favorites,
        'is_favorite': isFavorite,
        'duration': duration,
        'source_240': source_240,
        'mv_type': mvType,
        'source_origin_str': sourceOriginStr,
        'tag_list': tagList,
        'is_pay': isPay,
        'discount': discount,
        'discount_coins': discountCoins,
        'is_package': isPackage,
        'preview_url': previewUrl,
        // 'member': member.toString(),
        'description': description,
        'img_url': imgUrl,
        'type': type,
        'router': router,
        'url_str': urlStr,
        'link_url': linkUrl,
        'url': url,
        'resource_url': resourceUrl,
        'redirect_type': redirectType,
        'report_id': reportId,
        'report_type': reportType,
        'video_type_id': videoTypeId ?? '',
        'video_type_name': videoTypeName ?? '',
        'video_content_type': videoContentType,
        'recommend_trace_id': recommendTraceId,
        'video_tag_key': videoTagKey,
        'video_tag_name': videoTagName,
        'media_id': mediaId,
      };
}

class HotFollowUseRecommendModel {
  final List<RecommendBloggerModel>? recommendBlogger;
  final List<VlogModel>? bloggerVlogs;

  HotFollowUseRecommendModel({
    this.recommendBlogger,
    this.bloggerVlogs,
  });

  factory HotFollowUseRecommendModel.fromJson(Map<String, dynamic> json) =>
      HotFollowUseRecommendModel(
        recommendBlogger: json['recommend_blogger'] == null
            ? null
            : List<RecommendBloggerModel>.from(json['recommend_blogger']
                .map((e) => RecommendBloggerModel.fromJson(e))),
        bloggerVlogs: json['blogger_mvs'] == null
            ? null
            : List<VlogModel>.from(
                json['blogger_mvs'].map((e) => VlogModel.fromJson(e))),
      );

  Map<String, dynamic> toJson() => {
        'recommend_blogger': recommendBlogger?.map((e) => e.toJson()),
        'blogger_mvs': bloggerVlogs?.map((e) => e.toJson()),
      };
}

class RecommendBloggerModel {
  final int? aff;
  final String? nickname;
  final String? thumb;
  final String? releasedAt;
  final List<VlogModel>? mvs;
  int? isFollow;
  final String? vipStr;
  final String? fansCt;
  final String? vlogCt;
  final String? likeCt;

  RecommendBloggerModel({
    this.aff,
    this.nickname,
    this.thumb,
    this.releasedAt,
    this.mvs,
    this.isFollow,
    this.vipStr,
    this.fansCt,
    this.vlogCt,
    this.likeCt,
  });

  factory RecommendBloggerModel.fromJson(Map<String, dynamic> json) =>
      RecommendBloggerModel(
        aff: json['aff'],
        nickname: json['nickname'],
        thumb: json['thumb'],
        releasedAt: json['released_at'],
        mvs: json['mvs'] == null
            ? null
            : List<VlogModel>.from(
                json['mvs'].map((e) => VlogModel.fromJson(e))),
        isFollow: json['is_follow'],
        vipStr: json['vip_str'],
        fansCt: json['fans_ct'].toString(),
        vlogCt: json['vlog_ct'].toString(),
        likeCt: json['like_ct'].toString(),
      );

  Map<String, dynamic> toJson() => {
        'aff': aff,
        'nickname': nickname,
        'thumb': thumb,
        'released_at': releasedAt,
        'mvs': mvs?.map((e) => e.toJson()),
        'is_follow': isFollow,
        'vip_str': vipStr,
        'fans_ct': fansCt,
        'vlog_ct': vlogCt,
        'like_ct': likeCt,
      };
}
