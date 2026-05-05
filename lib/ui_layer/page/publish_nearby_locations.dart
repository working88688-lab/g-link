import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:g_link/domain/model/feed_models.dart';
import 'package:geocoding/geocoding.dart' as gc;
import 'package:geolocator/geolocator.dart';

/// 已知 [Position] 时加载附近地点（Photon + 系统逆地理），不含定位权限流程。
Future<List<PublishLocationInput>> loadNearbyForKnownPosition(
  BuildContext context,
  Position pos,
) async {
  final locale = Localizations.localeOf(context);
  final localeId = locale.countryCode != null && locale.countryCode!.isNotEmpty
      ? '${locale.languageCode}_${locale.countryCode}'
      : locale.languageCode;

  List<PublishLocationInput> photon = const [];
  List<PublishLocationInput> plat = const [];
  try {
    photon = await _fetchPhotonReverse(
      pos.latitude,
      pos.longitude,
      locale.languageCode,
    );
  } catch (_) {}
  try {
    plat = await _placemarkDerivedNearby(
      pos.latitude,
      pos.longitude,
      localeId,
    );
  } catch (_) {}

  return _dedupePublishLocations([...photon, ...plat]);
}

/// 获取当前坐标：先处理权限（含 iOS [LocationPermission.unableToDetermine]），
/// 再在「系统定位关闭」时仍尝试单次定位，最后 [Geolocator.getLastKnownPosition] 兜底。
Future<Position?> tryGetPublishPosition() async {
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.unableToDetermine) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    return null;
  }

  Future<Position?> currentOrLast() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 20),
        ),
      );
    } catch (_) {
      return await Geolocator.getLastKnownPosition();
    }
  }

  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    final masked = await currentOrLast();
    if (masked != null) return masked;
    return await Geolocator.getLastKnownPosition();
  }

  final p = await currentOrLast();
  return p ?? await Geolocator.getLastKnownPosition();
}

Future<List<PublishLocationInput>> _fetchPhotonReverse(
  double lat,
  double lon,
  String langCode,
) async {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
      headers: {
        'User-Agent': 'G-Link/1.0 (publish nearby; contact: app)',
        'Accept': 'application/json',
      },
    ),
  );
  final res = await dio.get<Map<String, dynamic>>(
    'https://photon.komoot.io/reverse',
    queryParameters: <String, dynamic>{
      'lat': lat,
      'lon': lon,
      'lang': langCode,
      'limit': 20,
    },
  );
  final data = res.data;
  if (data == null) return const [];
  return _parsePhotonFeatures(data, fallbackLat: lat, fallbackLon: lon);
}

List<PublishLocationInput> _parsePhotonFeatures(
  Map<String, dynamic> json, {
  required double fallbackLat,
  required double fallbackLon,
}) {
  final features = json['features'] as List? ?? const [];
  final out = <PublishLocationInput>[];
  for (final f in features) {
    if (f is! Map<String, dynamic>) continue;
    final props = Map<String, dynamic>.from(f['properties'] as Map? ?? {});
    final geom = f['geometry'];
    double lat = fallbackLat;
    double lon = fallbackLon;
    if (geom is Map && geom['coordinates'] is List) {
      final c = geom['coordinates'] as List;
      if (c.length >= 2) {
        lon = (c[0] as num).toDouble();
        lat = (c[1] as num).toDouble();
      }
    }

    final name = '${props['name'] ?? ''}'.trim();
    final street = '${props['street'] ?? ''}'.trim();
    final district = '${props['district'] ?? ''}'.trim();
    final city = '${props['city'] ?? props['county'] ?? ''}'.trim();
    final state = '${props['state'] ?? ''}'.trim();
    final country = '${props['country'] ?? ''}'.trim();

    var title = name;
    if (title.isEmpty) {
      title = [street, district, city].where((e) => e.isNotEmpty).join(' · ');
    }
    if (title.isEmpty) continue;

    final addrParts = <String>[
      if (street.isNotEmpty) street,
      if (district.isNotEmpty && district != title) district,
      if (city.isNotEmpty && city != title) city,
      if (state.isNotEmpty) state,
      if (country.isNotEmpty) country,
    ];
    var address = addrParts.join('');
    if (address.isEmpty) {
      address = [city, state, country].where((e) => e.isNotEmpty).join('');
    }

    out.add(
      PublishLocationInput(
        name: title,
        address: address.isEmpty ? null : address,
        latitude: lat,
        longitude: lon,
      ),
    );
  }
  return out;
}

Future<List<PublishLocationInput>> _placemarkDerivedNearby(
  double lat,
  double lon,
  String localeId,
) async {
  try {
    await gc.setLocaleIdentifier(localeId);
  } catch (_) {}
  final marks = await gc.placemarkFromCoordinates(lat, lon);
  if (marks.isEmpty) return const [];
  return _expandPlacemark(marks.first, lat, lon);
}

/// 从单次逆地理结果拆成多级「附近」条目（路名、区县、城市等），坐标均用当前定位点。
List<PublishLocationInput> _expandPlacemark(
  gc.Placemark p,
  double lat,
  double lon,
) {
  final out = <PublishLocationInput>[];
  void add(String title, String? address) {
    final t = title.trim();
    if (t.isEmpty) return;
    out.add(
      PublishLocationInput(
        name: t,
        address: address?.trim().isEmpty ?? true ? null : address!.trim(),
        latitude: lat,
        longitude: lon,
      ),
    );
  }

  final thoroughfare = (p.thoroughfare ?? '').trim();
  final subLocality = (p.subLocality ?? '').trim();
  final locality = (p.locality ?? '').trim();
  final subAdmin = (p.subAdministrativeArea ?? '').trim();
  final admin = (p.administrativeArea ?? '').trim();
  final name = (p.name ?? '').trim();

  final areaLine = <String>[
    if (subLocality.isNotEmpty) subLocality,
    if (locality.isNotEmpty) locality,
    if (subAdmin.isNotEmpty) subAdmin,
    if (admin.isNotEmpty) admin,
  ].join('');

  if (name.isNotEmpty && name != thoroughfare) {
    add(name, areaLine.isEmpty ? null : areaLine);
  }
  if (thoroughfare.isNotEmpty) {
    add(thoroughfare, areaLine.isEmpty ? null : areaLine);
  }
  if (subLocality.isNotEmpty) {
    add(subLocality, locality.isNotEmpty ? locality : null);
  }
  if (locality.isNotEmpty && locality != subLocality) {
    add(locality, admin.isNotEmpty ? admin : null);
  }
  if (subAdmin.isNotEmpty &&
      subAdmin != locality &&
      subAdmin != subLocality) {
    add(subAdmin, admin.isNotEmpty ? admin : null);
  }
  if (admin.isNotEmpty && admin != locality && admin != subAdmin) {
    add(admin, null);
  }

  return out;
}

List<PublishLocationInput> _dedupePublishLocations(
  List<PublishLocationInput> raw,
) {
  final seen = <String>{};
  final out = <PublishLocationInput>[];
  for (final p in raw) {
    final k = p.name.trim().toLowerCase();
    if (k.isEmpty) continue;
    if (seen.contains(k)) continue;
    seen.add(k);
    out.add(p);
    if (out.length >= 24) break;
  }
  return out;
}
