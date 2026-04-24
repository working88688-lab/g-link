import 'package:g_link/domain/type_def.dart';

class AuthUser {
  const AuthUser({
    required this.uid,
    required this.username,
    required this.nickname,
    required this.avatarUrl,
  });

  final int uid;
  final String username;
  final String nickname;
  final String avatarUrl;

  factory AuthUser.fromJson(Json json) {
    return AuthUser(
      uid: int.tryParse('${json['uid'] ?? 0}') ?? 0,
      username: '${json['username'] ?? ''}',
      nickname: '${json['nickname'] ?? ''}',
      avatarUrl: '${json['avatar_url'] ?? ''}',
    );
  }
}

class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
  });

  final String accessToken;
  final String refreshToken;
  final String tokenType;

  factory AuthTokens.fromJson(Json json) {
    return AuthTokens(
      accessToken: '${json['access_token'] ?? ''}',
      refreshToken: '${json['refresh_token'] ?? ''}',
      tokenType: '${json['token_type'] ?? 'Bearer'}',
    );
  }
}

class AuthResultData {
  const AuthResultData({
    required this.user,
    required this.tokens,
    required this.isNewUser,
    required this.requireOnboarding,
  });

  final AuthUser user;
  final AuthTokens tokens;
  final bool isNewUser;
  final bool requireOnboarding;

  factory AuthResultData.fromJson(Json json) {
    return AuthResultData(
      user: AuthUser.fromJson(Json.from(json['user'] ?? {})),
      tokens: AuthTokens.fromJson(Json.from(json['tokens'] ?? {})),
      isNewUser: json['is_new_user'] == true,
      requireOnboarding: json['require_onboarding'] == true,
    );
  }
}
