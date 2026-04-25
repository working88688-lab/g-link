class VideoItemModel {
  final String id;
  final String authorName;
  final String authorAvatar;
  final String location;
  final String title;
  final List<String> tags;
  final String desc;
  final String music;
  final int likes;
  final int comments;
  final int favorites;
  final int shares;
  bool isFollowing = false;
  bool isLiked;
  bool isFavorited;
  bool isMuted = false;

  VideoItemModel({
    required this.id,
    required this.authorName,
    required this.authorAvatar,
    required this.location,
    required this.title,
    required this.tags,
    required this.desc,
    required this.music,
    required this.likes,
    required this.comments,
    required this.favorites,
    required this.shares,
    this.isLiked = false,
    this.isFavorited = false,
  });
}

final mockVideoItems = List.generate(
  8,
  (i) => VideoItemModel(
    id: '$i',
    authorName: 'creator_$i',
    authorAvatar: '',
    location: ['杭州·西湖', '上海·外滩', '北京·三里屯', '广州·珠江'][i % 4],
    title: ['一只穿云箭', '城市日记', '光与影', '流浪的风'][i % 4],
    tags: ['#打卡', '#日常', '#治愈系'],
    desc: '吹吹晚风，感受大自然的馈赠，舒舒服服的一天就从这里开始...',
    music: ['都是月亮惹的祸 | 章鱼', 'Summer | 久石让', '明天你好 | 牛奶咖啡'][i % 3],
    likes: 9837 + i * 123,
    comments: 637 + i * 31,
    favorites: 218 + i * 17,
    shares: 218 + i * 9,
    isLiked: i % 3 == 0,
    isFavorited: i % 5 == 0,
  ),
);
