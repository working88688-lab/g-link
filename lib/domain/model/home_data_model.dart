class HomeData {
  HomeData({
    required this.versionMsg,
    this.timestamp,
    required this.config,
    this.notice,
    this.ads,
    this.startScreenAds,
    this.popAds,
    this.help,
    this.noticeApps,
    this.upgradeApk = '',
    this.upgradeFail,
  });

  final VersionMsg? versionMsg;
  final int? timestamp;
  final Notice? notice;
  final List<Notice>? popAds;
  final Config config;
  final AdModel? ads;
  final List<AdModel>? startScreenAds;
  final List<Help>? help;
  final List<Notice>? noticeApps;
  final String upgradeApk;
  final UpgradeFailHint? upgradeFail;

  factory HomeData.fromJson(Map<String, dynamic> json) => HomeData(
        versionMsg: json['versionMsg'] == null
            ? null
            : VersionMsg.fromJson(json['versionMsg']),
        notice: json['notice'] == null ? null : Notice.fromJson(json['notice']),
        timestamp: json['timestamp'],
        config: Config.fromJson(json['config']),
        ads: json['ads'] == null ? null : AdModel.fromJson(json['ads']),
        popAds: List<Notice>.from(
            json['pop_ads']?.map((x) => Notice.fromJson(x)) ?? []),
        help: List<Help>.from(json['help']?.map((e) => Help.fromJson(e))),
        noticeApps: List<Notice>.from(
            json['notice_app']?.map((x) => Notice.fromJson(x)) ?? []),
        startScreenAds: List<AdModel>.from(
            json['start_screen_ads']?.map((x) => AdModel.fromJson(x)) ?? []),
        upgradeApk: json['upgrade_apk'] ?? '',
        upgradeFail: json['upgrade_fail'] == null
            ? null
            : UpgradeFailHint.fromJson(json['upgrade_fail']),
      );
}

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

class Config {
  Config({
    required this.imgBase,
    required this.imgUploadUrl,
    this.mp4UploadUrl,
    this.mobileMp4UploadUrl,
    required this.uploadImgKey,
    this.uploadMp4Key,
    this.uuid,
    this.github,
    this.officeSite,
    this.officialGroup,
    this.line,
    this.m3u8Encrypt,
    this.videoEncryptApi,
    this.videoEncryptReferer,
    this.videoEncryptM3u8,
    required this.vipLevelStr,
    required this.vipNameStr,
    required this.navId,
    this.lqNavid,
    this.dmNavid,
    this.mhNavid,
    this.awNavid,
    this.githubUrl,
    this.linesUrl,
    this.tipsShareText,
    this.girlCommentOption,
    this.shortSite,
    this.proxyJoinNum,
    this.solution,
    this.personAds,
    this.dayPrice,
    this.coverIds,
    this.coverVipStr,
    this.coverTips,
    this.showApp,
    required this.potatoGroup,
    required this.tgGroup,
    required this.payAi,
    required this.seedVipTip,
    required this.seedCoinsTip,
    required this.wdaiStr,
    required this.vipLevelAwqStr,
    required this.vipNameAwqStr,
    required this.faceCoins,
    required this.stripCoins,
    required this.payAiMagic,
    required this.payAiDraw,
    this.openLive,
    this.imCoins,
    this.imTip,
    this.bindEmailTip,
    this.joinChatGroupCoins,
    this.pwaDownloadUrl,
    this.r2URL,
    this.r2Key,
    this.r2CompleteURL,
    this.pwa_apk,
    this.keywords,
    this.description,
    this.title,
    this.adVersion,
    this.nav_prepend,
    this.nav_default,
    required this.payAiAudio,
    required this.payAiNovel,
    required this.payAiKiss,
    required this.aiAudioFontCt,
    required this.buryPoint,
  });

  final int? imCoins;
  final String? imTip;
  final String? bindEmailTip;
  final String? dayPrice;
  final dynamic personAds;
  final String imgUploadUrl;
  final String? solution;
  final String? mp4UploadUrl;
  final String? mobileMp4UploadUrl;
  final String uploadImgKey;
  final String? uploadMp4Key;
  final String? uuid;
  final String? tipsShareText;
  final String? github;
  final String? officeSite;
  final String? officialGroup;
  final String? shortSite;
  final String imgBase;
  final List<String>? line;
  final int? m3u8Encrypt;
  final String? videoEncryptApi;
  final String? videoEncryptReferer;
  final String? videoEncryptM3u8;
  final List<String> vipLevelStr;
  final String vipNameStr;
  final int? navId;
  final int? lqNavid;
  final int? dmNavid;
  final int? mhNavid;
  final int? awNavid;
  final String? githubUrl;
  final List<String>? linesUrl;
  final String? girlCommentOption;
  final String? proxyJoinNum;
  final List<String>? coverIds;
  final List<String>? coverVipStr;
  final String? coverTips;

  final int payAi;
  final int? showApp;

  final String potatoGroup;
  final String tgGroup;

  final String seedVipTip;
  final String seedCoinsTip;
  final String wdaiStr;
  final List<String> vipLevelAwqStr;
  final String vipNameAwqStr;
  final int faceCoins;
  final int stripCoins;
  final int? openLive;
  final int? joinChatGroupCoins; //加入soul群聊所需金币数

  final String? pwaDownloadUrl;

  //R2分片上传
  final String? r2URL;
  final String? r2Key;
  final String? r2CompleteURL;

  //paw_apk下载
  final String? pwa_apk;

  //seo
  final String? keywords;
  final String? description;
  final String? title;

  final int? adVersion;

  List<NavPrependModel>? nav_prepend;
  int? nav_default;

  final int payAiMagic;
  final int payAiDraw;

  final int payAiAudio;
  final int payAiNovel;
  final int payAiKiss;
  final int aiAudioFontCt; //音频生成字数限制
  ReportConfig buryPoint;

  factory Config.fromJson(Map<String, dynamic> json) => Config(
        nav_default: json['nav_default'],
        nav_prepend: List<NavPrependModel>.from(
            json['nav_prepend']?.map((x) => NavPrependModel.fromJson(x)) ?? []),
        dayPrice: json['day_price'],
        personAds: json['person_ads'],
        imgUploadUrl: json['img_upload_url'],
        solution: json['solution'] ?? '',
        mp4UploadUrl: json['mp4_upload_url'],
        mobileMp4UploadUrl: json['mobile_mp4_upload_url'],
        uploadImgKey: json['upload_img_key'] ?? '',
        uploadMp4Key: json['upload_mp4_key'],
        uuid: json['uuid'],
        github: json['github'],
        officeSite: json['office_site'],
        officialGroup: json['official_group'],
        imgBase: json['img_base'],
        line: json['line']?.map((x) => x).toList(),
        m3u8Encrypt: json['m3u8_encrypt'],
        videoEncryptApi: json['video_encrypt_api'],
        videoEncryptReferer: json['video_encrypt_referer'],
        videoEncryptM3u8: json['video_encrypt_m3u8'],
        vipLevelStr:
            List<String>.from(json['vip_level_str']?.map((x) => x) ?? []),
        vipNameStr: json['vip_name_str'] ?? '',
        navId: json['nav_id'],
        lqNavid: json['lq_navid'],
        dmNavid: json['dm_navid'],
        mhNavid: json['mh_navid'],
        awNavid: json['aw_id'] ?? 0,
        shortSite: json['short_site'],
        githubUrl: json['github_url'],
        linesUrl: List<String>.from(json['lines_url']?.map((x) => x) ?? []),
        tipsShareText: json['tips_share_text'],
        girlCommentOption: json['girl_comment_option'] ??
            json['girl_comment_option'].toString(),
        proxyJoinNum: json['proxy_join_num']?.toString(),
        coverIds: List<String>.from(json['cover_ids']?.map((x) => x) ?? []),
        coverVipStr: json['cover_vip_str']?.map((x) => x).toList(),
        coverTips: json['cover_tips'],
        payAi: json['pay_ai'] ?? 0,
        showApp: json['show_app'],
        potatoGroup: json['potato_group'] ?? '',
        tgGroup: json['tg_group'] ?? '',
        seedVipTip: json['seed_vip_tip'] ?? '',
        seedCoinsTip: json['seed_coins_tip'] ?? '',
        wdaiStr: json['wdai_str'] ?? '',
        vipLevelAwqStr:
            List<String>.from(json['vip_level_awq_str']?.map((x) => x) ?? []),
        vipNameAwqStr: json['vip_name_awq_str'] ?? '',
        faceCoins: json['face_coins'],
        stripCoins: json['strip_coins'],
        openLive: json['open_live'],
        imCoins: json['im_coins'],
        imTip: json['im_tip'],
        bindEmailTip: json['bind_email_tip'],
        joinChatGroupCoins: json['join_chat_group_coins'] ?? 0,
        pwaDownloadUrl: json['pwa_download_url'] ?? '',
        r2URL: json['r2URL'] ?? '',
        r2Key: json['r2Key'] ?? '',
        r2CompleteURL: json['r2CompleteURL'] ?? '',
        pwa_apk: json['pwa_apk'] ?? '',
        keywords: json['keywords'] ?? '',
        description: json['description'] ?? '',
        title: json['title'] ?? '',
        adVersion: json['ad_version'] ?? 0,
        payAiMagic: json['pay_ai_magic'] ?? 0,
        payAiDraw: json['pay_ai_draw'] ?? 0,
        payAiAudio: json['pay_ai_audio'] ?? 0,
        payAiNovel: json['pay_ai_novel'] ?? 0,
        payAiKiss: json['pay_ai_kiss'] ?? 0,
        aiAudioFontCt: json['ai_audio_font_ct'] ?? 0,
        buryPoint: ReportConfig.fromJson(json['bury_point'] ?? {}),
      );

  Map<String, dynamic> toJson() => {
        'nav_default': nav_default,
        'nav_prepend': nav_prepend?.map((e) => e).toList() ?? [],
        'day_price': dayPrice,
        'person_ads': personAds,
        'img_upload_url': imgUploadUrl,
        'solution': solution ?? '',
        'mp4_upload_url': mp4UploadUrl,
        'mobile_mp4_upload_url': mobileMp4UploadUrl,
        'upload_img_key': uploadImgKey,
        'upload_mp4_key': uploadMp4Key,
        'uuid': uuid,
        'github': github,
        'office_site': officeSite,
        'official_group': officialGroup,
        'img_base': imgBase,
        'line': line?.map((e) => e).toList(),
        'm3u8_encrypt': m3u8Encrypt,
        'video_encrypt_api': videoEncryptApi,
        'video_encrypt_referer': videoEncryptReferer,
        'video_encrypt_m3u8': videoEncryptM3u8,
        'vip_level_str': vipLevelStr.map((e) => e).toList(),
        'vip_name_str': vipNameStr,
        'nav_id': navId,
        'lq_navid': lqNavid,
        'dm_navid': dmNavid,
        'mh_navid': mhNavid,
        'aw_navid': awNavid,
        'short_site': shortSite,
        'github_url': githubUrl,
        'tips_share_text': tipsShareText,
        'lines_url': linesUrl?.map((e) => e).toList(),
        'girl_comment_option': girlCommentOption,
        'proxy_join_num': proxyJoinNum,
        'cover_ids': coverIds?.map((e) => e).toList(),
        'cover_vip_str': coverVipStr?.map((e) => e).toList(),
        'cover_tips': coverTips,
        'pay_ai': payAi,
        'show_app': showApp,
        'potato_group': potatoGroup,
        'tg_group': tgGroup,
        'seed_vip_tip': seedVipTip,
        'seed_coins_tip': seedCoinsTip,
        'face_coins': faceCoins,
        'strip_coins': stripCoins,
        'open_live': openLive,
        'im_coins': imCoins,
        'im_tip': imTip,
        'bind_email_tip': bindEmailTip,
        'join_chat_group_coins': joinChatGroupCoins,
        'pwa_download_url': pwaDownloadUrl,
        'r2URL': r2URL,
        'r2Key': r2Key,
        'r2CompleteURL': r2CompleteURL,
        'pwa_apk': pwa_apk,
        'keywords': keywords,
        'description': description,
        'title': title,
        'ad_version': adVersion,
        'pay_ai_magic': payAiMagic,
        'pay_ai_draw': payAiDraw,
        'ai_audio_font_ct': aiAudioFontCt,
        'bury_point': buryPoint.toJson(),
      };
}

class Notice {
  Notice({
    required this.id,
    this.url,
    this.linkUrl,
    this.imgUrl,
    this.title,
    this.content,
    this.router,
    this.visibleType,
    this.type,
    this.height,
    this.width,
    this.urlStr,
    this.reportId = 0,
    this.reportType,
    this.redirectType,
    this.adType,
    this.adSlotName,
    this.advertiseCode,
    this.advertiseLocationCode,
  });

  final int id;
  final String? url;
  final String? linkUrl;
  final String? imgUrl;
  final String? title;
  final String? content;
  final String? router;
  final int? visibleType;
  final String? type;
  final int? height;
  final int? width;
  final String? urlStr;
  final int reportId;
  final int? reportType;
  final int? redirectType;
  final String? adType;
  final String? adSlotName;
  final String? advertiseCode;
  final String? advertiseLocationCode;

  factory Notice.fromJson(Map<String, dynamic> json) => Notice(
        id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
        url: json['url'] as String?,
        linkUrl: json['link_url'] as String?,
        imgUrl: json['img_url'] as String?,
        title: json['title'] as String?,
        content: json['content'] as String?,
        router: json['router'] as String?,
        visibleType: json['visible_type'] is int
            ? json['visible_type']
            : int.tryParse('${json['visible_type']}'),
        type: json['type']?.toString(),
        height: json['height'] is int
            ? json['height']
            : int.tryParse('${json['height']}'),
        width: json['width'] is int
            ? json['width']
            : int.tryParse('${json['width']}'),
        urlStr: json['url_str'] as String?,
        reportId: json['report_id'] is int
            ? json['report_id']
            : int.tryParse('${json['report_id']}'),
        reportType: json['report_type'] is int
            ? json['report_type']
            : int.tryParse('${json['report_type']}'),
        redirectType: json['redirect_type'] is int
            ? json['redirect_type']
            : int.tryParse('${json['redirect_type']}'),
        adType: json['ad_type']?.toString(),
        adSlotName: json['ad_slot_name'] as String?,
        advertiseCode: json['advertise_code'] as String?,
        advertiseLocationCode: json['advertise_location_code'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'url': url,
        'link_url': linkUrl,
        'img_url': imgUrl,
        'title': title,
        'content': content,
        'router': router,
        'visible_type': visibleType,
        'type': type,
        'height': height,
        'width': width,
        'url_str': urlStr,
        'report_id': reportId,
        'report_type': reportType,
        'redirect_type': redirectType,
        'ad_type': adType,
        'ad_slot_name': adSlotName,
        'advertise_code': advertiseCode,
        'advertise_location_code': advertiseLocationCode,
      };
}

class VersionMsg {
  VersionMsg({
    this.version,
    this.type,
    this.apk,
    this.tips,
    this.must,
    this.status,
    this.message,
    this.mstatus,
    this.channel,
    this.sha256,
  });

  /// 版本号
  final String? version;
  final String? type;

  /// 更新app用下载网址
  final String? apk;

  /// 更新描述
  final String? tips;

  /// 更新开关 0 不更新  1 强制更新 2 非强制更新
  final int? must;
  final int? status;

  /// 公告描述
  final String? message;

  /// 系统公告状态 0 没有 1通知 2禁用
  final int? mstatus;
  final String? channel;
  final String? sha256;

  factory VersionMsg.fromJson(Map<String, dynamic> json) => VersionMsg(
        version: json['version'],
        type: json['type'],
        apk: json['apk'],
        tips: json['tips'],
        must: json['must'],
        status: json['status'],
        message: json['message'],
        mstatus: json['mstatus'],
        channel: json['channel'],
        sha256: json['sha256'] ?? "",
      );

  Map<String, dynamic> toJson() => {
        'version': version,
        'type': type,
        'apk': apk,
        'tips': tips,
        'must': must,
        'status': status,
        'message': message,
        'mstatus': mstatus,
        'channel': channel,
        "sha256": sha256,
      };
}

class Help {
  Help({
    required this.items,
    required this.type,
    required this.name,
  });

  final List<HelpItem> items;
  final int type;
  final String name;

  factory Help.fromJson(Map<String, dynamic> json) => Help(
        items: List.from(json['items'].map((x) => HelpItem.fromJson(x))),
        type: json['type'],
        name: json['name'],
      );
}

class HelpItem {
  HelpItem(
      {required this.id,
      required this.question,
      required this.answer,
      required this.status,
      required this.type,
      required this.views,
      required this.createdAt,
      required this.updatedAt});

  final int id;
  final String question;
  final String answer;
  final int status;
  final int type;
  final int? views;
  final String createdAt;
  final String updatedAt;

  factory HelpItem.fromJson(Map<String, dynamic> json) => HelpItem(
      id: json['id'],
      question: json['question'],
      answer: json['answer'],
      status: json['status'],
      type: json['type'],
      views: json['views'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at']);
}

class NavPrependModel {
  NavPrependModel({
    this.label,
    this.type,
    this.sort,
    this.value,
  });

  final String? label;
  final int? type;
  final int? sort;
  final String? value;

  factory NavPrependModel.fromJson(Map<String, dynamic> json) =>
      NavPrependModel(
        label: json['label'],
        type: json['type'],
        sort: json['sort'],
        value: json['value'],
      );

  Map<String, dynamic> toJson() => {
        'label': label,
        'type': type,
        'sort': sort,
        'value': value,
      };
}

class ReportConfig {
  ReportConfig({
    this.clickAppId = '',
    this.clickTransitPath = '',
    this.isReportOrderPaid = 0,
    this.isReportCoinConsume = 0,
    this.isReportNavigation = 0,
    this.isReportAppPageView = 0,
    this.isReportPageClick = 0,
    this.isReportAdvertising = 0,
    this.isReportPageLifecycle = 0,
    this.isReportVideoEvent = 0,
    this.isReportVideoLike = 0,
    this.isReportVideoComment = 0,
    this.isReportVideoCollect = 0,
    this.isReportVideoPurchase = 0,
    this.isReportKeywordSearch = 0,
    this.isReportKeywordClick = 0,
    this.isReportAdImpression = 0,
    this.isReportAdClick = 0,
    this.isEncryption = 0,
    this.encryptionKey = '',
    this.encryptionIv = '',
    this.signKey = '',
    this.authenticationKey = '',
    this.authenticationTime = '',
  });

  final String clickAppId;
  final String clickTransitPath;
  final int isReportOrderPaid;
  final int isReportCoinConsume;
  final int isReportNavigation;
  final int isReportAppPageView;
  final int isReportPageClick;
  final int isReportAdvertising;
  final int isReportPageLifecycle;
  final int isReportVideoEvent;
  final int isReportVideoLike;
  final int isReportVideoComment;
  final int isReportVideoCollect;
  final int isReportVideoPurchase;
  final int isReportKeywordSearch;
  final int isReportKeywordClick;
  final int isReportAdImpression;
  final int isReportAdClick;
  final int isEncryption;
  final String encryptionKey;
  final String encryptionIv;
  final String signKey;
  final String authenticationKey;
  final String authenticationTime;

  factory ReportConfig.fromJson(Map<String, dynamic> json) {
    return ReportConfig(
      clickAppId: json['click_app_id'] ?? '',
      clickTransitPath: json['click_transit_path'] ?? '',
      isReportOrderPaid: json['is_report_order_paid'] ?? 0,
      isReportCoinConsume: json['is_report_coin_consume'] ?? 0,
      isReportNavigation: json['is_report_navigation'] ?? 0,
      isReportAppPageView: json['is_report_app_page_view'] ?? 0,
      isReportPageClick: json['is_report_page_click'] ?? 0,
      isReportAdvertising: json['is_report_advertising'] ?? 0,
      isReportPageLifecycle: json['is_report_page_lifecycle'] ?? 0,
      isReportVideoEvent: json['is_report_video_event'] ?? 0,
      isReportVideoLike: json['is_report_video_like'] ?? 0,
      isReportVideoComment: json['is_report_video_comment'] ?? 0,
      isReportVideoCollect: json['is_report_video_collect'] ?? 0,
      isReportVideoPurchase: json['is_report_video_purchase'] ?? 0,
      isReportKeywordSearch: json['is_report_keyword_search'] ?? 0,
      isReportKeywordClick: json['is_report_keyword_click'] ?? 0,
      isReportAdImpression: json['is_report_ad_impression'] ?? 0,
      isReportAdClick: json['is_report_ad_click'] ?? 0,
      isEncryption: json['is_encryption'] ?? 0,
      encryptionKey: json['encryption_key'] ?? '',
      encryptionIv: json['encryption_iv'] ?? '',
      signKey: json['sign_key'] ?? '',
      authenticationKey: json['authentication_key'] ?? '',
      authenticationTime: '${json['authentication_time'] ?? ''}',
    );
  }

  Map<String, dynamic> toJson() => {
        'click_app_id': clickAppId,
        'click_transit_path': clickTransitPath,
        'is_report_order_paid': isReportOrderPaid,
        'is_report_coin_consume': isReportCoinConsume,
        'is_report_navigation': isReportNavigation,
        'is_report_app_page_view': isReportAppPageView,
        'is_report_page_click': isReportPageClick,
        'is_report_advertising': isReportAdvertising,
        'is_report_page_lifecycle': isReportPageLifecycle,
        'is_report_video_event': isReportVideoEvent,
        'is_report_video_like': isReportVideoLike,
        'is_report_video_comment': isReportVideoComment,
        'is_report_video_collect': isReportVideoCollect,
        'is_report_video_purchase': isReportVideoPurchase,
        'is_report_keyword_search': isReportKeywordSearch,
        'is_report_keyword_click': isReportKeywordClick,
        'is_report_ad_impression': isReportAdImpression,
        'is_report_ad_click': isReportAdClick,
        'is_encryption': isEncryption,
        'encryption_key': encryptionKey,
        'encryption_iv': encryptionIv,
        'sign_key': signKey,
        'authentication_key': authenticationKey,
        'authentication_time': authenticationTime,
      };
}

class UpgradeFailHint {
  final String title;
  final String label;
  final String url;

  const UpgradeFailHint({
    required this.title,
    required this.label,
    required this.url,
  });

  factory UpgradeFailHint.fromJson(Map<String, dynamic> json) {
    return UpgradeFailHint(
      title: json['title'] ?? '',
      label: json['label'] ?? '',
      url: json['url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'label': label,
        'url': url,
      };
}
