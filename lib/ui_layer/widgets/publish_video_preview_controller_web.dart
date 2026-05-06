import 'package:cross_file/cross_file.dart';
import 'package:video_player/video_player.dart';

Future<VideoPlayerController> publishVideoPreviewCreateController(XFile x) async {
  return VideoPlayerController.networkUrl(Uri.parse(x.path));
}
