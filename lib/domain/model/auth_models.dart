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

class AuthCountryCode {
  const AuthCountryCode({
    required this.display,
    required this.request,
    required this.name,
    this.iso2 = '',
    this.flagEmoji = '',
  });

  final String display;
  final String request;
  final String name;
  final String iso2;
  final String flagEmoji;

  factory AuthCountryCode.fromJson(Json json) {
    final dialRaw =
        '${json['dial_code'] ?? json['country_code'] ?? json['phone_code'] ?? ''}'
            .trim();
    final codeRaw = '${json['code'] ?? ''}'.trim();
    final rawCode = dialRaw.isNotEmpty ? dialRaw : codeRaw;
    final digits = rawCode.replaceAll(RegExp(r'[^0-9]'), '');
    final request = digits.isNotEmpty ? digits : rawCode.replaceAll('+', '');
    final display = request.isEmpty ? '+01' : '+$request';
    final name =
        '${json['name'] ?? json['country_name'] ?? json['label'] ?? display}';
    final iso2Raw =
        '${json['iso2'] ?? json['iso_code'] ?? json['country_iso2'] ?? codeRaw}'
            .toUpperCase();
    final iso2 = RegExp(r'^[A-Z]{2}$').hasMatch(iso2Raw) ? iso2Raw : '';
    final flagEmoji =
        '${json['flag_emoji'] ?? json['emoji'] ?? json['flag'] ?? ''}';
    return AuthCountryCode(
      display: display,
      request: request.isEmpty ? '1' : request,
      name: name,
      iso2: iso2,
      flagEmoji: flagEmoji,
    );
  }
}
