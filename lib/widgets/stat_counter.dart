import 'package:flutter/material.dart';

class StatCounter extends StatelessWidget {
  final String label;
  final int count;
  final VoidCallback? onTap;
  final bool isTappable;

  const StatCounter({
    Key? key,
    required this.label,
    required this.count,
    this.onTap,
    this.isTappable = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget content = Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
      ],
    );

    if (isTappable && onTap != null) {
      return InkWell(
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }
}
