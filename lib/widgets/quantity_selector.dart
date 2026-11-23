import 'package:flutter/material.dart';

/// Control de cantidad (− valor +).
class QuantitySelector extends StatelessWidget {
  final int value;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;
  final bool compact;

  const QuantitySelector({
    super.key,
    required this.value,
    this.onDecrement,
    this.onIncrement,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = compact ? 18.0 : 22.0;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Disminuir',
            visualDensity: compact ? VisualDensity.compact : null,
            iconSize: size,
            onPressed: onDecrement,
            icon: const Icon(Icons.remove),
          ),
          SizedBox(
            width: compact ? 24 : 32,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: compact ? 15 : 18, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            tooltip: 'Aumentar',
            visualDensity: compact ? VisualDensity.compact : null,
            iconSize: size,
            onPressed: onIncrement,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
