import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SlideToCancelWidget extends StatefulWidget {
  final VoidCallback onCancel;

  const SlideToCancelWidget({Key? key, required this.onCancel})
    : super(key: key);

  @override
  State<SlideToCancelWidget> createState() => _SlideToCancelWidgetState();
}

class _SlideToCancelWidgetState extends State<SlideToCancelWidget> {
  double _dragPosition = 0.0;
  bool _isCancelled = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final sliderWidth = screenWidth * 0.8;
    final handleSize = 50.0;
    final maxDrag = sliderWidth - handleSize;

    return Container(
      width: sliderWidth,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Stack(
        children: [
          // Background text
          Center(
            child: Text(
              'slide_to_cancel'.tr,
              style: TextStyle(
                color: Colors.white.withOpacity(_isCancelled ? 0.0 : 1.0),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // Draggable handle
          Positioned(
            left: _dragPosition,
            top: 5,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _dragPosition = (_dragPosition + details.delta.dx).clamp(
                    0.0,
                    maxDrag,
                  );

                  // Check if dragged past 80% threshold
                  if (_dragPosition >= maxDrag * 0.8 && !_isCancelled) {
                    _isCancelled = true;
                    widget.onCancel();
                  }
                });
              },
              onPanEnd: (details) {
                // Snap back if not cancelled
                if (!_isCancelled) {
                  setState(() {
                    _dragPosition = 0.0;
                  });
                }
              },
              child: Container(
                width: handleSize,
                height: handleSize,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.red,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
