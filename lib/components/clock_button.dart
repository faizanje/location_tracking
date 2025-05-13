import 'package:flutter/material.dart';

class ClockButton extends StatelessWidget {
  final bool isClockIn;
  final bool isActive;
  final VoidCallback onPressed;

  const ClockButton({
    super.key,
    required this.isClockIn,
    required this.isActive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isActive ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: isClockIn ? Colors.green : Colors.red,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isClockIn ? Icons.login : Icons.logout),
          const SizedBox(width: 8),
          Text(isClockIn ? 'Clock In' : 'Clock Out'),
        ],
      ),
    );
  }
}
