import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class TrimEditorPainter extends CustomPainter {
  final Offset startPos;
  final Offset endPos;
  final double scrubberAnimationDx;
  final double circleSize;
  final double borderWidth;
  final double scrubberWidth;
  final bool showScrubber;
  final Color borderPaintColor;
  final Color circlePaintColor;
  final Color scrubberPaintColor;
  final double borderRadius;
  final VideoPlayerController videoPlayerController;
  TrimEditorPainter({
    @required this.startPos,
    @required this.endPos,
    @required this.scrubberAnimationDx,
    this.circleSize = 0.5,
    this.borderWidth = 3,
    this.scrubberWidth = 1,
    this.showScrubber = true,
    this.borderPaintColor = Colors.white,
    this.circlePaintColor = Colors.white,
    this.scrubberPaintColor = Colors.white,
    this.videoPlayerController,
    this.borderRadius = 10
  })  : assert(startPos != null),
        assert(endPos != null),
        assert(scrubberAnimationDx != null),
        assert(circleSize != null),
        assert(borderWidth != null),
        assert(scrubberWidth != null),
        assert(showScrubber != null),
        assert(borderPaintColor != null),
        assert(circlePaintColor != null),
        assert(scrubberPaintColor != null);

  @override
  void paint(Canvas canvas, Size size) {
    var borderPaint = Paint()
      ..color = borderPaintColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    var fillerPaint = Paint()
    ..color = borderPaintColor
    ..style = PaintingStyle.fill;

    var notSelectedBackgroundPaint = Paint()
    ..color = Colors.black38
    ..style = PaintingStyle.fill;

    var scrubberPaint = Paint()
      ..color = scrubberPaintColor
      ..strokeWidth = scrubberWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    var whitePaint = Paint()..strokeWidth = 1.5..color = Colors.white;

    final rect = RRect.fromRectXY(Rect.fromPoints(startPos, endPos),10,10);
    final _leftRRect = RRect.fromLTRBAndCorners(startPos.dx, 0, startPos.dx+10, endPos.dy, topLeft: Radius.circular(borderRadius), bottomLeft: Radius.circular(borderRadius));
    final _rightRRect = RRect.fromLTRBAndCorners(endPos.dx, 0, endPos.dx-10, endPos.dy, topRight: Radius.circular(borderRadius), bottomRight: Radius.circular(borderRadius));
    final _leftInsideRRect = RRect.fromLTRBAndCorners(startPos.dx+4,  endPos.dy*.25, startPos.dx+6, endPos.dy*.75, topLeft: Radius.circular(1), bottomLeft: Radius.circular(1));
    final _rightInsideRRect = RRect.fromLTRBAndCorners(endPos.dx-4,  endPos.dy*.25, endPos.dx-6, endPos.dy*.75, topRight: Radius.circular(1), bottomRight: Radius.circular(1));

    final _leftBackgroundRect = Rect.fromLTRB(0, 0, startPos.dx, endPos.dy);
    final _rightBackgroundRect = Rect.fromLTRB(size.width, 0, endPos.dx, endPos.dy);

    if (showScrubber) {
      if (scrubberAnimationDx.toInt() > startPos.dx.toInt()) {
        canvas.drawLine(
          Offset(scrubberAnimationDx, 0),
          Offset(scrubberAnimationDx, 0) + Offset(0, endPos.dy),
          scrubberPaint,
        );
      }
    }

    canvas.drawRect(_leftBackgroundRect, notSelectedBackgroundPaint);
    canvas.drawRect(_rightBackgroundRect, notSelectedBackgroundPaint);
    canvas.drawRRect(rect, borderPaint);
    canvas.drawRRect(_leftRRect, fillerPaint);
    canvas.drawRRect(_rightRRect, fillerPaint);
    canvas.drawRRect(_leftInsideRRect, whitePaint);
    canvas.drawRRect(_rightInsideRRect, whitePaint);

  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
