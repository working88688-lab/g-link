import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/ui_layer/image_paths.dart';
import 'package:g_link/ui_layer/page/chat/widgets/recommend_users_widget.dart';
import 'package:g_link/ui_layer/widgets/my_image.dart';
import 'models/search_models.dart';

// ─────────────────────────────────────────
//  用户搜索页
//  入口：消息列表页顶部菜单"搜索用户"
// ─────────────────────────────────────────

class UserSearchPage extends StatefulWidget {
  const UserSearchPage({super.key});

  @override
  State<UserSearchPage> createState() => _UserSearchPageState();
}

class _UserSearchPageState extends State<UserSearchPage> {
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();

  String _query = '';

  // ── 搜索结果 ──────────────────────────
  bool _isLoading = false;
  List<UserItem> _users = [];

  bool _showRecommend = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String val) {
    final kw = val.trim();
    setState(() {
      _query = kw;
      if (kw.isEmpty) {
        _users = [];
        _isLoading = false;
      }
    });
    if (kw.isNotEmpty) _search(kw);
  }

  // TODO: 替换为真实 API 调用
  Future<void> _search(String keyword) async {
    if (keyword.isEmpty || !mounted) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted || _query != keyword) return;
    setState(() {
      _isLoading = false;
      _users = [
        const UserItem(name: '优秀用户', followers: '5.4w粉丝'),
        const UserItem(name: '优秀达人', followers: '12w粉丝'),
        const UserItem(name: '优秀帅哥', followers: '899粉丝'),
      ];
    });
  }

  void _clearQuery() {
    _ctrl.clear();
    _onChanged('');
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Icon(Icons.arrow_back_ios, size: 20.sp, color: const Color(0xFF0F172B)),
        ),
        title: Text('搜索用户',
            style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w600, color: const Color(0xFF0F172B))),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            SearchInputBar(
              hintText: '搜索用户名或昵称',
              controller: _ctrl,
              focusNode: _focusNode,
              query: _query,
              onChanged: _onChanged,
              onClear: _clearQuery,
              showCancel: false,
            ),
            Expanded(child: _buildResults()),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_query.isEmpty)
      return SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          children: [SizedBox(height: 300.w), if (_showRecommend) RecommendUsersWidget(
            onClose: (){
              setState(() {
                _showRecommend = false;
              });
            },
          )],
        ),
      );
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF00C67E),
          strokeWidth: 2,
        ),
      );
    }
    if (_users.isEmpty) {
      return Center(
        child: Text('暂无结果', style: TextStyle(fontSize: 14.sp, color: const Color(0xFF62748E))),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: _users.length,
      itemBuilder: (_, i) => _UserTile(name: _users[i].name, followers: _users[i].followers, keyword: _query),
    );
  }
}

class _UserTile extends StatelessWidget {
  final String name;
  final String followers;
  final String keyword;

  const _UserTile({required this.name, required this.followers, required this.keyword});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.w),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF8F9FE)))),
      child: Column(
        children: [
          Row(
            children: [
              searchAvatar(size: 40.w),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600, color: const Color(0xFF0F172B)),
                    ),
                    Text("用户名:2231456asdoa", style: TextStyle(fontSize: 12.sp, color: const Color(0xFF62748E))),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.w),
                  decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFCCCCCC)), borderRadius: BorderRadius.circular(100.r)),
                  alignment: Alignment.center,
                  child: Text('已关注',
                      style: TextStyle(fontSize: 13.sp, color: Color(0xFF1A1F2C), fontWeight: FontWeight.w500)),
                ),
              ),
              SizedBox(
                width: 7.w,
              ),
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.w),
                  decoration: BoxDecoration(color: const Color(0xFF1A1F2C), borderRadius: BorderRadius.circular(100.r)),
                  alignment: Alignment.center,
                  child:
                      Text('发消息', style: TextStyle(fontSize: 13.sp, color: Colors.white, fontWeight: FontWeight.w500)),
                ),
              )
            ],
          ),
          SizedBox(
            height: 4.w,
          ),
          Row(
            children: [
              SizedBox(
                width: 40.w,
              ),
              SizedBox(width: 12.w),
              highlight(followers, followers.replaceAll("粉丝", ""),
                  base: TextStyle(fontSize: 12.sp, color: const Color(0xFF62748E)),
                  hl: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500, color: const Color(0xFF62748E)))
            ],
          )
        ],
      ),
    );
  }
}
