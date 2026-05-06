import '../../app_config.dart';

class AppRouterPaths {
  static const root = '/';

  /// 登入
  static const login = '/login';

  /// 注册
  static const register = '/register';

  /// 忘记密码
  static const forgotPassword = '/forgot_password';

  /// 首页
  static const home = '/home';

  /// 短视频
  static const shortVideo = '/short_video';

  /// 发布
  static const publish = '/publish';
  static const publishAlbum = '/publish_album';

  /// 消息
  static const message = '/message';

  /// 我的
  static const mine = '/mine';
  static const mineEditProfile = '/mine/edit_profile';
  static const mineRecommendFollow = '/mine/recommend_follow';

  /// 关注列表页（互关 / 关注 / 粉丝）。
  /// 设计上是 Mine 分支内的子路由——保留底部主 tab 栏可见，与典型社交 app 的
  /// 「粉丝/关注」二级页一致。配合 [MineFollowListRoute] 使用。
  /// 路径相对值（child route）：实际地址为 `/mine/follow_list`。
  static const mineFollowList = 'follow_list';

  /// 他人主页：和个人主页共用 [MinePage]，但通过 [OtherProfileRoute]
  /// 入口推到根 Navigator 上 —— 不展示底部主 tab 栏，左上角是返回键。
  static const userProfile = '/user_profile';

  /// 用户最新帖子列表页：← + 「最新帖子」+ 卡片列表（数据源 `/users/{uid}/posts`）。
  /// 走根 Navigator 全屏覆盖，从首页顶部 stories 头像点击进入。
  static const userPosts = '/user_posts';

  /// 引导页
  static const guide = '/guide';

  /// 反馈提交
  static const feedbackSubmit = '/feedback_submit';

  /// 投诉用户
  static const complaint = '/complaint';

  /// 聊天会话详情
  static const chatConversation = '/chat_conversation';

  /// 消息 - 用户搜索
  static const userSearch = '/user_search';

  /// 消息 - 全局搜索（联系人+聊天记录）
  static const globalSearch = '/global_search';

  /// 聊天 - 聊天记录搜索
  static const chatRecordsSearch = '/chat_records_search';

  /// 暗网
  static const anWang = '/anWang';

  /// 直播
  static const zhiBo = '/zhib';

  /// 短视频
  static const vlog = '/vlog';

  static const vlogTag = '/vlogTag/:tag';

  static const vlogSecond = '/vlogSecond';

  /// soul 群聊列表
  static const soulGroupChatList = '/soulGroupChatList';

  /// soul 群聊--聊天详情列表
  static const soulGroupDetailChatList = '/soulGroupDetailChatList';

  /// soul 群聊--全部成员列表
  static const soulGroupMembersList = '/soulGroupMembersList';

  /// soul 群聊置顶消息详情界面
  static const soulGroupChatTopMsg = '/soulGroupChatTopMsg';

  /// 动漫
  static const cartoon = '/cartoon';

  /// 动漫更多
  static const cartoonMore = '/cartoonMore/:sort/:title';

  /// 动漫详情
  static const cartoonDetail = '/cartoonDetail';

  /// 游戏
  static const game = '/game';

  /// 游戏更多
  static const gameMore = '/gameMore/:sort/:title';

  /// 游戏 热销/热门/最新/手游
  static const gameNav = '/gameNav/:type/:title';

  /// 游戏详情
  static const gameDetail = '/gameDetail';

  /// 游戏标签
  static const gameTag = '/gameTag/:tag';

  /// 资源
  static const ziYuan = '/ziYuan';

  /// 咸鱼
  static const ych = '/ych';

  /// 社区
  static const community = '/community';

  /// 标签视频列表
  static const moreVideo = '/moreVideo/:name/:id';

  /// 搜索
  static const search = '/search';

  /// 搜索结果
  static const searchResult = '/searchResult/:title';

  /// 社区标签
  static const communityTagDetail = '/communityTagDetail/:id';

  /// 社区帖子详情
  static const communityTieztDetail = '/communityTieztDetail/:id';

  /// 社区发布帖子
  static const communityIssue = '/communityIssue/:type/:org';

  /// 社区发布帖子
  static const voicePlayerContent = '/voicePlayerContent';

  /// 社区选择版块
  static const communityModule = '/communityModule';

  /// 下载帖子详情
  static const bitPostDetail = '/bitPostDetail/:id';

  /// 我的 - VIP充值
  static const mineVipCenter = '/mineVipCenter';

  /// 我的 - VIP升级
  static const mineVipUpgrade = '/mineVipUpgrade';

  /// 我的 - 金币充值
  static const mineCoinRecharge = '/mineCoinRecharge';

  /// 我的 - 金币明细
  static const mineCoinDetail = '/mineCoinDetail';

  /// 我的 - 充值记录
  static const mineRechargeRecord = '/mineRechargeRecord/:type';

  /// 我的 - 帖子
  static const minePost = '/minePost';

  /// 我的 - 收藏
  static const mineCollection = '/mineCollection';

  /// 我的 - 关注
  static const mineFansFollow = '/mineFansFollow';

  /// 我的 - 原创入驻
  static const mineOriginalEnter = '/mineOriginalEnter';

  /// 我的 - 购买
  static const mineBuy = '/mineBuy';

  /// 我的 - AI
  static const mineAIRecord = '/minAIRecord';

  /// 我的 - 下载
  static const mineDownload = '/mineDownload';

  /// 我的 - 邀请码/兑换码/编辑用户名
  static const mineFillCode = '/mineFillCode/:title';

  /// 我的 绑定邮箱
  static const mineBindEmail = '/mine_bind_email';

  /// 我的 - 帮助
  static const mineHelp = '/mineHelp';

  /// 我的 - 通知
  static const notification = '/notification';

  /// 我的 - 官方交流群
  static const mineOfficialGroup = '/mineOfficialGroup';

  /// 我的 - 客服消息
  static const customerService = '/customerService';

  /// 我的 - 系统消息
  static const mineSystemMessage = '/mineSystemMessage';

  /// 我的 - 系统通知详情
  static const systemNotificationDetail = '/systemNotificationDetail';

  /// 我的 - 消息中心
  static const mineMessageCenter = '/mineMessageCenter';

  /// 我的 - 设置
  static const mineSetup = '/mineSetup';

  /// 我的 - 去推广
  static const mineShareToUser = '/mineShareToUser';

  /// 我的 - 推广记录
  static const mineShareToUserRecord = '/mineShareToUserRecord';

  /// 我的 - 福利
  static const mineWelfare = '/mineWelfare/:index';

  /// 代理 - 赚钱
  static const mineAgent = '/mineAgent';

  /// 代理 - 明细
  static const mineAgentProfit = '/mineAgentProfit';

  /// 代理 - 推广数据
  static const mineAgentPromoteData = '/mineAgentPromoteData';

  /// 我的 - 提现
  static const mineWithdrawal = '/mineWithdrawal/:isAgent';

  /// 我的 - 提现 - 明细
  static const mineWithdrawalRecord = '/mineWithdrawalRecord';

  /// 我的 - 提现 - 银行卡列表
  static const mineWithdrawalBankList = '/mineWithdrawalBankList';

  /// 我的 - 收益明细
  static const mineIncomeDetail = '/mineIncomeDetail';

  /// 我的 - 关注
  static const mineFollowing = '/mineFollowing';

  /// 我的 - 申请入驻
  static const originalEnter = '/originalEnter';

  /// 用户中心
  static const userCenter = '/userCenter/:aff';

  /// IM聊天
  static const chatMessage = '/chatMessage/:toUuid/:nickName/:thumb';

  /// 长视频详情页
  static const videoDetail = '/videoDetail';

  /// 直播详情页
  static const livesDetail = '/livesDetail';

  /// AI服务
  static const aiServer = '/aiServer';

  /// AI魔法
  static const aiMagicDetail = '/aiMagicDetail';

  /// AI魔法列表页
  static const aiMagic = '/aiMagic';

  /// AI绘画
  static const aiArt = '/aiArt';

  /// AI换脸
  static const aiFaceSwap = '/aiFaceSwap';

  /// AI视频换脸
  static const aiVideoFaceSwap = '/aiVideoFaceSwap';

  /// AI脱衣
  static const aiOffDeRobe = '/aiOffDeRobe';

  /// AI接吻
  static const aiKiss = '/aiKiss';

  /// AI小说
  static const aiNovel = '/aiNovel';

  /// AI语音
  static const aiAudio = '/aiAudio';

  /// AI小说详情
  static const aiNovelDetail = '/aiNovelDetail';

  /// ASMR
  static const asmr = '/asmr';

  /// 种子下载
  static const torrentDownload = '/torrentDownload';

  /// 榜单
  static const rankList = '/rankList';

  static const mediaViewer = '/mediaViewer';

  static const localVideo = '/localVideo';

  static const localVoice = '/localVoice';

  static const webView = '/${BuildConfig.webViewPathName}/:url';
}
