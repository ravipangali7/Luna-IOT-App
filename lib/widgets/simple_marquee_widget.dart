import 'package:flutter/material.dart';

class SimpleMarqueeText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final double scrollAxisExtent;
  final Duration scrollDuration;
  final Duration pauseDuration;
  final bool autoStart;
  final TextAlign textAlign;

  const SimpleMarqueeText({
    super.key,
    required this.text,
    this.style,
    this.scrollAxisExtent = 200.0,
    this.scrollDuration = const Duration(seconds: 5),
    this.pauseDuration = const Duration(seconds: 2),
    this.autoStart = true,
    this.textAlign = TextAlign.left,
  });

  @override
  State<SimpleMarqueeText> createState() => _SimpleMarqueeTextState();
}

class _SimpleMarqueeTextState extends State<SimpleMarqueeText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isTextOverflowing = false;
  double _textWidth = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.scrollDuration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));

    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkTextOverflow();
      });
    }
  }

  @override
  void didUpdateWidget(SimpleMarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _checkTextOverflow();
    }
  }

  void _checkTextOverflow() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final textPainter = TextPainter(
          text: TextSpan(text: widget.text, style: widget.style),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        );
        textPainter.layout();

        final isOverflowing = textPainter.width > widget.scrollAxisExtent;

        if (mounted) {
          setState(() {
            _isTextOverflowing = isOverflowing;
            _textWidth = textPainter.width;
          });

          if (isOverflowing && widget.autoStart) {
            _startMarquee();
          }
        }
      }
    });
  }

  void _startMarquee() {
    if (!_isTextOverflowing) return;

    _controller.reset();
    _controller.repeat(); // Continuous loop without pause
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isTextOverflowing) {
      return Text(
        widget.text,
        style: widget.style,
        textAlign: widget.textAlign,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      );
    }

    return Container(
      width: widget.scrollAxisExtent,
      height: 20, // Fixed height
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            // Calculate offset so text starts from right and moves left
            // When animation is 0, text should be at the right edge
            // When animation is 1, text should be completely off the left edge
            final totalScrollDistance = _textWidth + widget.scrollAxisExtent;
            final offset =
                widget.scrollAxisExtent -
                (totalScrollDistance * _animation.value);

            return Transform.translate(
              offset: Offset(offset, 0),
              child: Text(
                widget.text,
                style: widget.style,
                textAlign: widget.textAlign,
                maxLines: 1,
                overflow: TextOverflow.visible,
              ),
            );
          },
        ),
      ),
    );
  }
}
