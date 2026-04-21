import 'package:flutter/material.dart';
import 'package:g_link/ui_layer/theme.dart';

class MinePage extends StatefulWidget {
  const MinePage({super.key});

  @override
  State<MinePage> createState() => _MinePageState();
}

class _MinePageState extends State<MinePage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '这是我的页面',
        style: MyTheme.white04_12,
      ),
    );
  }
}
