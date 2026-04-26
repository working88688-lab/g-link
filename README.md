# g_link

A new Flutter project.

## Getting Started

# 添加图片权限  sudo chmod -R 755 <path>

# 添加 model进 lib/domain/create_export_domains.dart  dart lib/domain/create_export_domains.dart
# 添加 image文件进 image_paths.dart  dart lib/images_to_dart.dart

# 生成.g.dart文件：fvm flutter pub run build_runner build 或者  fvm flutter pub run build_runner watch

# 脚本执行生成文件并删除前后的冲突 flutter pub run build_runner build --delete-conflicting-outputs

# 打包，先fvm切换flutter sdk到匹配版本
# 打包apk 执行 fvm flutter build apk --obfuscate --split-debug-info=HLQ_Struggle
# 打包web 执行
# 升级版本号
fvm flutter build web --web-renderer html --release
fvm dart add_version.dart
# apk 名称格式 包名_版本号_时间戳.apk

## 接口地址 https://api.zywsbgha.cc/docs
