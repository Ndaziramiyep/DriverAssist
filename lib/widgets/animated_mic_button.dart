import 'package:flutter/material.dart';

class AnimatedMicButton extends StatefulWidget {
  final bool isListening;
  final VoidCallback onTap;

  const AnimatedMicButton({super.key, required this.isListening, required this.onTap});

  @override
  State<AnimatedMicButton> createState() => _AnimatedMicButtonState();
}

class _AnimatedMicButtonState extends State<AnimatedMicButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.isListening)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                double scale = 1.0 + 0.4 * _controller.value;
                return Container(
                  width: 48 * scale,
                  height: 48 * scale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.withOpacity(0.2 + 0.3 * (1 - _controller.value)),
                  ),
                );
              },
            ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                if (widget.isListening)
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: Icon(
              widget.isListening ? Icons.mic : Icons.mic_none,
              color: widget.isListening ? Colors.blue : Colors.grey,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
} 