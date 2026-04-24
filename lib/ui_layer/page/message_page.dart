import 'package:flutter/material.dart';
import 'package:g_link/ui_layer/page/message_page_v2.dart';

/// Legacy entry kept for compatibility, now delegating to V2 message flow.
class MessagePage extends StatelessWidget {
  const MessagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MessagePageV2();
  }
}
