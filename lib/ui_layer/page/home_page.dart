import 'package:flutter/material.dart';
import 'package:g_link/ui_layer/theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '这是首页',
        style: MyTheme.white04_12,
      ),
    );
  }
}
