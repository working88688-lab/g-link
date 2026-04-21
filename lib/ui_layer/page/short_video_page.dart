import 'package:flutter/material.dart';
import 'package:g_link/ui_layer/theme.dart';

class ShortVideoPage extends StatefulWidget {
  const ShortVideoPage({super.key});

  @override
  State<ShortVideoPage> createState() => _ShortVideoPageState();
}

class _ShortVideoPageState extends State<ShortVideoPage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '这是短视频',
        style: MyTheme.white04_12,
      ),
    );
  }
}
