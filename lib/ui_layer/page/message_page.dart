import 'package:flutter/material.dart';
import 'package:g_link/ui_layer/theme.dart';

class MessagePage extends StatefulWidget {
  const MessagePage({super.key});

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '这是消息',
        style: MyTheme.white04_12,
      ),
    );
  }
}
