import 'dart:io';
import 'package:flutter/material.dart';
import '../../domain/ml_service.dart';

class RedactionLayer extends StatefulWidget {
  final File imageFile;
  final List<RedactRegion> regions;
  final Size imageSize;

  final ValueChanged<int> onRegionTapped;
  final ValueChanged<Rect> onCustomDrawStart;
  final ValueChanged<Rect> onCustomDrawUpdate;
  final VoidCallback onCustomDrawEnd;

  const RedactionLayer({
    super.key,
    required this.imageFile,
    required this.regions,
    required this.imageSize,
    required this.onRegionTapped,
    required this.onCustomDrawStart,
    required this.onCustomDrawUpdate,
    required this.onCustomDrawEnd,
  });

  @override
  State<RedactionLayer> createState() => _RedactionLayerState();
}

class _RedactionLayerState extends State<RedactionLayer> {
  Offset? _startPoint;
  Offset? _currentPoint;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: widget.imageSize.width / widget.imageSize.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scaleX = constraints.maxWidth / widget.imageSize.width;
          final scaleY = constraints.maxHeight / widget.imageSize.height;

          return GestureDetector(
            onPanStart: (details) {
              final localPos = details.localPosition;
              final originalPos = Offset(
                localPos.dx / scaleX,
                localPos.dy / scaleY,
              );
              _startPoint = originalPos;
              _currentPoint = originalPos;
              widget.onCustomDrawStart(
                Rect.fromPoints(_startPoint!, _currentPoint!),
              );
            },
            onPanUpdate: (details) {
              if (_startPoint == null) return;
              final localPos = details.localPosition;
              final originalPos = Offset(
                localPos.dx / scaleX,
                localPos.dy / scaleY,
              );

              final clampedDx = originalPos.dx.clamp(
                0.0,
                widget.imageSize.width,
              );
              final clampedDy = originalPos.dy.clamp(
                0.0,
                widget.imageSize.height,
              );

              _currentPoint = Offset(clampedDx, clampedDy);
              widget.onCustomDrawUpdate(
                Rect.fromPoints(_startPoint!, _currentPoint!),
              );
            },
            onPanEnd: (details) {
              _startPoint = null;
              _currentPoint = null;
              widget.onCustomDrawEnd();
            },
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.file(widget.imageFile, fit: BoxFit.contain),
                ),
                ...widget.regions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final region = entry.value;
                  return Positioned(
                    left: region.rect.left * scaleX,
                    top: region.rect.top * scaleY,
                    width: region.rect.width * scaleX,
                    height: region.rect.height * scaleY,
                    child: GestureDetector(
                      onTap: () => widget.onRegionTapped(index),
                      child: Container(
                        decoration: BoxDecoration(
                          color: region.isApplied
                              ? Colors.black
                              : const Color(0x66FFFF00),
                          border: Border.all(
                            color: region.isApplied ? Colors.black : Colors.red,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}
