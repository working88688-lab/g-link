import 'package:flutter/material.dart';

class AppBottomSheet {
  static Future<void> showSimpleList({
    required BuildContext context,
    required String title,
    required List<String> items,
    IconData leadingIcon = Icons.circle_outlined,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          itemCount: items.length + 1,
          itemBuilder: (ctx, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
              );
            }
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(leadingIcon, size: 20),
              title: Text(items[i - 1]),
            );
          },
        );
      },
    );
  }

  static Future<void> showActions({
    required BuildContext context,
    required String title,
    required List<({IconData icon, String label, VoidCallback onTap})> actions,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: actions
                    .map(
                      (action) => InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          Navigator.of(ctx).pop();
                          action.onTap();
                        },
                        child: SizedBox(
                          width: 88,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.grey.shade200,
                                child: Icon(action.icon, color: Colors.black87),
                              ),
                              const SizedBox(height: 6),
                              Text(action.label,
                                  style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}
