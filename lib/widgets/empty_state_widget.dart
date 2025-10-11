// lib/widgets/empty_state_widget.dart
import 'package:flutter/material.dart';

class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.message,
    this.actionText,
    this.onAction,
  });

  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, color: Colors.blueGrey.shade400, size: 40),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center),
            if (actionText != null) ...[
              const SizedBox(height: 10),
              FilledButton(onPressed: onAction, child: Text(actionText!)),
            ],
          ],
        ),
      ),
    );
  }
}