import 'package:flutter/material.dart';
import 'package:g_link/ui_layer/theme.dart';

class PublishPage extends StatefulWidget {
  const PublishPage({super.key});

  @override
  State<PublishPage> createState() => _PublishPageState();
}

class _PublishPageState extends State<PublishPage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '这是发布页',
        style: MyTheme.white04_12,
      ),
    );
  }
}
