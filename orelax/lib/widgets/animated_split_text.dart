import 'package:flutter/material.dart';

/// Animated character-by-character text widget with staggered entrance animation
class AnimatedSplitText extends StatefulWidget {
  final String text;
  final TextStyle textStyle;
  final Duration staggerDelay;
  final Duration duration;
  final Offset from;
  final Offset to;
  final Curve curve;
  final VoidCallback? onComplete;

  const AnimatedSplitText({
    super.key,
    required this.text,
    required this.textStyle,
    this.staggerDelay = const Duration(milliseconds: 80),
    this.duration = const Duration(milliseconds: 700),
    this.from = const Offset(0, 30),
    this.to = const Offset(0, 0),
    this.curve = Curves.easeOut,
    this.onComplete,
  });

  @override
  State<AnimatedSplitText> createState() => _AnimatedSplitTextState();
}

class _AnimatedSplitTextState extends State<AnimatedSplitText>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _opacityAnimations;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    final charCount = widget.text.length;
    _controllers =
        List.generate(charCount, (index) => AnimationController(duration: widget.duration, vsync: this));

    _opacityAnimations = _controllers
        .map((controller) => Tween<double>(begin: 0, end: 1).animate(
            CurvedAnimation(parent: controller, curve: widget.curve)))
        .toList();

    _slideAnimations = _controllers
        .map((controller) => Tween<Offset>(begin: widget.from, end: widget.to)
            .animate(CurvedAnimation(parent: controller, curve: widget.curve)))
        .toList();

    // Stagger animation start
    for (int i = 0; i < charCount; i++) {
      Future.delayed(widget.staggerDelay * i, () {
        if (mounted) {
          _controllers[i].forward();
        }
      });
    }

    // Notify completion after last character finishes
    Future.delayed(
        widget.staggerDelay * (charCount - 1) + widget.duration, () {
      if (mounted) {
        widget.onComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.text.length, (index) {
        final char = widget.text[index];
        return SlideTransition(
          position: _slideAnimations[index],
          child: FadeTransition(
            opacity: _opacityAnimations[index],
            child: Text(
              char,
              style: widget.textStyle,
            ),
          ),
        );
      }),
    );
  }
}
