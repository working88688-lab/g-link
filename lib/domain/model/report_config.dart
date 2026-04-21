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