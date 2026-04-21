import 'dart:io';

import 'package:dio/dio.dart';
import 'package:g_link/app_global.dart';
import 'package:g_link/crypto.dart';
import 'package:g_link/domain/model/vlog_model.dart';
import 'package:g_link/ui_layer/video_player/utils/shelf_proxy.dart';
import 'package:g_link/utils/common_utils.dart';
import 'package:hive/hive.dart';
import 'package:permission_handler/permission_handler.dart';

Dio dio = Dio();

// 短视频
class PreloadUtils {
  static List preloadTasks = []; // 下载任务队列
  static bool downloading = false; // 是否存在下载任务
  static int finishCount = 0; // 当前下载完成的分片数量
  static bool currentRemove = false; // 当前下载任务是否被删除
  static bool alreadyAsked = false; // 是否申请过文件夹访问权限

  // 接收预加载视频数组
  static Future<void> receivePreloadData(List<VlogModel> dataArr) async {
    removeCurrentTask();

    for (var videoInfo in dataArr) {
      Map taskInfo = {
        "id": videoInfo.id.toString(),
        "urlPath": videoInfo.source_240.toString().isEmpty
            ? videoInfo.previewUrl
            : videoInfo.source_240,
        "title": videoInfo.title,
        "cover_thumb": videoInfo.coverVertical,
        "downloading": false,
        "isWaiting": true
      };
      await createPreloadTask(taskInfo);
    }
  }

  static Future<void> removeCurrentTask() async {
    if (preloadTasks.isEmpty) {
      return;
    }
    preloadTasks.clear();
    downloading = false;
    currentRemove = true;
  }

  // 创建预加载任务
  /*
   * taskInfo数据结构:
   * id              视频id
   * urlPath         下载地址（需解密）
   * title           视频标题
   * cover_thumb      视频封面
   * downloading     视频下载状态 bool
   * isWaiting       是否在下载队列中 bool
   * url             视频m3u8储存地址
   * tsLists         视频ts链接队列
   * localM3u8       本地m3u8文件 string
   * tsListsFinished 已下载完成的ts队列
   * progress        视频下载进度
   */
  static createPreloadTask(Map taskInfo) async {
    bool havePermission = await getPermission();
    if (!havePermission) {
      return;
    }

    double remainMemory = await CommonUtils.getRemainMemory();
    // 运行内存RAM用1024进位，存储内存ROM用1000进位
    // 设备内存小于5Gb，取消短视频预加载
    if (remainMemory < 5 * 1000.0 * 1000.0 * 1000.0 && remainMemory >= 0.0) {
      return;
    }

    try {
      Box box = await Hive.openBox('hjsq_preload_box');
      List tasks = box.get('preload_video_tasks') ?? [];
      int existTaskIndex = tasks.indexWhere((e) => e["id"] == taskInfo["id"]);

      // 存在下载任务
      if (tasks.isNotEmpty && existTaskIndex != -1) {
        if (tasks[existTaskIndex]["downloading"] ||
            tasks[existTaskIndex]["progress"] == 1) {
        } else if (downloading) {
          preloadTasks.add({"taskInfo": tasks[existTaskIndex]});
          tasks[existTaskIndex]["isWaiting"] = true;
          box.put("preload_video_tasks", tasks);
        } else {
          preloadTasks.add({"taskInfo": tasks[existTaskIndex]});
          downloadContent(tasks[existTaskIndex], box);
          tasks[existTaskIndex]["downloading"] = true;
          tasks[existTaskIndex]["isWaiting"] = false;
          box.put("preload_video_tasks", tasks);
        }
        return;
      }
      // 生成本地m3u8和ts下载列表
      Map tsData = await getTsList(taskInfo["urlPath"]);
      // String localM3u8 = tsData["localM3u8"];
      List<String> tsLists = tsData["tsLists"];
      taskInfo["tsLists"] = tsLists;
      // taskInfo["localM3u8"] = localM3u8;
      taskInfo["tsListsFinished"] = [];
      // 添加下载队列
      preloadTasks.add({"taskInfo": taskInfo});
      // 获取储存地址
      String folderName = getFolderName(taskInfo["urlPath"]);
      String fileName = stringByHashEncode(taskInfo["urlPath"].substring(
          taskInfo["urlPath"].lastIndexOf('/') + 1,
          taskInfo["urlPath"].indexOf('.m3u8')));
      String saveDirectory = '${await getCachePath(folderName)}$fileName.m3u8';
      // 存储本地m3u8文件
      // await File(saveDirectory).writeAsString(localM3u8);
      taskInfo["url"] = saveDirectory;
      if (!downloading) {
        taskInfo["downloading"] = true;
        taskInfo["isWaiting"] = false;
        downloadContent(taskInfo, box);
      }
      // 储存下载任务信息
      taskInfo["progress"] = 0;
      tasks.insert(0, taskInfo);
      box.put("preload_video_tasks", tasks);
    } catch (e) {
      CommonUtils.log('预加载存储错误：$e');
    }
  }

  static Future<void> downloadContent(Map taskInfo, Box box) async {
    List tsListsFinished = taskInfo["tsListsFinished"];
    initStatus(tsListsFinished.length);
    List<String> tsLists = [];
    tsLists.addAll(taskInfo["tsLists"]);
    String saveDirectory =
        taskInfo["url"].substring(0, taskInfo["url"].lastIndexOf("/"));
    // 提取未完成的下载任务队列
    if (tsListsFinished.isNotEmpty) {
      tsLists.removeWhere((e) {
        for (var i = 0; i < tsListsFinished.length; i++) {
          if (tsListsFinished[i] == e) {
            return true;
          }
        }
        return false;
      });
    }

    int index = 0;
    int taskNum;
    List tasks;
    Future start() async {
      // 删除任务中断下载
      if (currentRemove) {
        return;
      }
      try {
        String savePath = saveDirectory +
            "/" +
            stringByHashEncode(tsLists[index].substring(
                tsLists[index].lastIndexOf("/") + 1,
                tsLists[index].contains(".ts")
                    ? (tsLists[index].indexOf(".ts"))
                    : (tsLists[index].indexOf(".key")))) +
            (tsLists[index].contains(".ts") ? ".ts_temp" : ".key_temp");
        index = await downloadItem(tsLists[index], savePath, index,
            taskInfo["id"], taskInfo["tsLists"].length, box);
        if (currentRemove) {
          return;
        }
        if (index >= tsLists.length - 1) {
          // 完成
          // 存储完成后的下载任务信息
          tasks = box.get('preload_video_tasks') ?? [];
          taskNum = tasks.indexWhere((e) => e["id"] == taskInfo["id"]);
          if (taskNum == -1) return;
          tasks[taskNum]["progress"] = 1;
          tasks[taskNum]["downloading"] = false;
          box.put("preload_video_tasks", tasks);
          // 下载完成，开始下一个任务
          if (preloadTasks.isNotEmpty) {
            preloadTasks.removeAt(0);
          }
          startNext();
        } else {
          index++;
          start();
        }
      } catch (e) {
        // 下载失败，开始下个任务
        tasks = box.get('preload_video_tasks') ?? [];
        taskNum = tasks.indexWhere((e) => e["id"] == taskInfo["id"]);
        if (taskNum == -1) return;
        tasks[taskNum]["downloading"] = false;
        box.put("preload_video_tasks", tasks);
        if (preloadTasks.isNotEmpty) {
          preloadTasks.removeAt(0);
        }
        startNext();
      }
    }

    start();
  }

  // 开始下个任务
  static startNext() async {
    if (preloadTasks.isNotEmpty) {
      Box box = await Hive.openBox('hjsq_preload_box');
      List tasks = box.get('preload_video_tasks') ?? [];
      preloadTasks[0]["taskInfo"]["downloading"] = true;
      int taskNum =
          tasks.indexWhere((e) => e["id"] == preloadTasks[0]["taskInfo"]["id"]);
      if (taskNum == -1) return;
      tasks[taskNum]["downloading"] = true;
      tasks[taskNum]["isWaiting"] = false;
      box.put("preload_video_tasks", tasks);
      downloadContent(tasks[taskNum], box);
    } else {
      downloading = false;
    }
  }

  // 单个下载方法
  static Future<int> downloadItem(String urlPath, String savePath, int index,
      String id, int tsTotal, Box box) async {
    Future<int> start() async {
      if (currentRemove) {
        return index;
      }
      try {
        await dio.download(urlPath, savePath,
            onReceiveProgress: (int count, int total) async {
          if (count >= total) {
            // 储存下载进度
            finishCount++;
            List tasks = box.get('preload_video_tasks') ?? [];
            int taskNum = tasks.indexWhere((e) => e["id"] == id);
            if (taskNum == -1) return;
            tasks[taskNum]["progress"] = finishCount / tsTotal;
            tasks[taskNum]["downloading"] = true;
            tasks[taskNum]["tsListsFinished"].add(urlPath);
            box.put("preload_video_tasks", tasks);

            final File file = File(savePath);
            if (await file.exists()) {
              await file.rename(savePath.replaceAll("_temp", ""));
            }
          }
        });
        return index;
      } catch (e) {
        return start();
      }
    }

    int a = await start();
    return a;
  }

  // 初始化下载状态
  static initStatus(int finishNum) {
    downloading = true;
    currentRemove = false;
    finishCount = finishNum;
  }

  // 视频解密，返回ts队列
  static Future<Map> getTsList(String urlPath) async {
    // 视频地址解密
    String decrypted;
    var res = await Dio().get(urlPath);
    if (AppGlobal.m3u8Encrypt == '1') {
      decrypted = PlatformAwareCrypto.decryptM3U8(res.data);
    } else {
      decrypted = res.data;
    }
    decrypted = _checkIV(decrypted);
    // String localM3u8 = await parseM3U8(decrypted, 1);
    // 整理key和ts链接
    List<String> lists = decrypted.split("#EXTINF:");
    List<String> tsLists = [];
    for (var el in lists) {
      var regSrcExp = RegExp(
          r'(http|ftp|https):\/\/[\w\-_]+(\.[\w\-_]+)+([\w\-\.,@?^=%&amp;:/~\+#]*[\w\-\@?^=%&amp;/~\+#])?');
      String matchfix = regSrcExp.stringMatch(el) ?? "";
      tsLists.add(matchfix);
    }
    // return {"localM3u8": localM3u8, "tsLists": tsLists};
    return {"tsLists": tsLists};
  }

  static String _checkIV(String data) {
    if (data.contains("IV=") == false) {
      String ivData = data.replaceAll(
          "#EXT-X-KEY:METHOD=AES-128,", "#EXT-X-KEY:METHOD=AES-128,IV=0x0,");
      return ivData;
    }
    return data;
  }

  // 请求权限
  static Future<bool> getPermission() async {
    PermissionStatus storageStatus = await Permission.storage.status;
    if (storageStatus == PermissionStatus.denied) {
      if (!alreadyAsked) {
        storageStatus = await Permission.storage.request();
        alreadyAsked = true;
        if (storageStatus == PermissionStatus.denied ||
            storageStatus == PermissionStatus.permanentlyDenied) {
          return false;
        }
        return true;
      } else {
        return false;
      }
    } else if (storageStatus == PermissionStatus.permanentlyDenied) {
      return false;
    }
    return true;
  }
}
