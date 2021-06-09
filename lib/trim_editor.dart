import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_trimmer/thumbnail_viewer.dart';
import 'package:video_trimmer/trim_editor_painter.dart';
import 'package:video_trimmer/video_trimmer.dart';
import 'package:better_player/better_player.dart';

class TrimEditor extends StatefulWidget {
  final double viewerWidthMinusPadding;
  final double viewerHeight;
  final double circleSize;
  final double circleSizeOnDrag;
  final Color circlePaintColor;
  final Color borderPaintColor;
  final Color scrubberPaintColor;
  final int thumbnailQuality;
  final bool showDuration;
  final TextStyle durationTextStyle;
  final int numberOfThumbNail;
  final Function(double startValue)? onChangeStart;
  final Function(double endValue)? onChangeEnd;
  final Function(bool isPlaying)? onChangePlaybackState;
  final Trimmer trimmer;

  /// Widget for displaying the video trimmer.
  ///
  /// This has frame wise preview of the video with a
  /// slider for selecting the part of the video to be
  /// trimmed.
  ///
  /// The required parameters are [viewerWidthMinusPadding] & [viewerHeight]
  ///
  /// * [viewerWidthMinusPadding] to define the total trimmer area width.
  ///
  ///
  /// * [viewerHeight] to define the total trimmer area height.
  ///
  ///
  /// The optional parameters are:
  ///
  /// * [circleSize] for specifying a size to the holder at the
  /// two ends of the video trimmer area, while it is `idle`.
  /// By default it is set to `5.0`.
  ///
  ///
  /// * [circleSizeOnDrag] for specifying a size to the holder at
  /// the two ends of the video trimmer area, while it is being
  /// `dragged`. By default it is set to `8.0`.
  ///
  ///
  /// * [circlePaintColor] for specifying a color to the circle.
  /// By default it is set to `Colors.white`.
  ///
  ///
  /// * [borderPaintColor] for specifying a color to the border of
  /// the trim area. By default it is set to `Colors.white`.
  ///
  ///
  /// * [scrubberPaintColor] for specifying a color to the video
  /// scrubber inside the trim area. By default it is set to
  /// `Colors.white`.
  ///
  ///
  /// * [thumbnailQuality] for specifying the quality of each
  /// generated image thumbnail, to be displayed in the trimmer
  /// area.
  ///
  ///
  /// * [showDuration] for showing the start and the end point of the
  /// video on top of the trimmer area. By default it is set to `true`.
  ///
  ///
  /// * [durationTextStyle] is for providing a `TextStyle` to the
  /// duration text. By default it is set to
  /// `TextStyle(color: Colors.white)`
  ///
  ///
  /// * [onChangeStart] is a callback to the video start position.
  ///
  ///
  /// * [onChangeEnd] is a callback to the video end position.
  ///
  ///
  /// * [onChangePlaybackState] is a callback to the video playback
  /// state to know whether it is currently playing or paused.
  ///
  TrimEditor(
    this.trimmer, {
    Key? key,
    required this.viewerWidthMinusPadding,
    required this.viewerHeight,
    this.circleSize = 5.0,
    this.circleSizeOnDrag = 8.0,
    this.circlePaintColor = Colors.white,
    this.borderPaintColor = Colors.white,
    this.scrubberPaintColor = Colors.white,
    this.thumbnailQuality = 75,
    this.showDuration = true,
    this.numberOfThumbNail = 8,
    this.durationTextStyle = const TextStyle(
      color: Colors.white,
    ),
    this.onChangeStart,
    this.onChangeEnd,
    this.onChangePlaybackState,
  })  :super(key: key);

  @override
  _TrimEditorState createState() => _TrimEditorState();
}

class _TrimEditorState extends State<TrimEditor> with TickerProviderStateMixin {
  File? _videoFile;

  double _videoStartPos = 0.0;
  double _videoEndPos = 0.0;

  bool _canUpdateStart = true;
  bool _isLeftDrag = true;

  Offset _startPos = Offset(0, 0);
  Offset _endPos = Offset(0, 0);

  double _startFraction = 0.0;
  double _endFraction = 1.0;

  int _videoDuration = 0;
  int _currentPosition = 0;

  double _thumbnailViewerW = 0.0;
  double _thumbnailViewerH = 0.0;

  late final _circleSize;

  ThumbnailViewer? thumbnailWidget;

  late final Animation<double> _scrubberAnimation;
  late final AnimationController _animationController;
  late final Tween<double> _linearTween;

  BetterPlayerController get betterPlayerController => widget.trimmer.betterVideoPlayer;

  @override
  void initState() {
    super.initState();

    _circleSize = widget.circleSize;

    _videoFile = widget.trimmer.videoFile;
    _thumbnailViewerH = widget.viewerHeight;

    _thumbnailViewerW = widget.viewerWidthMinusPadding;

    _endPos = Offset(_thumbnailViewerW, _thumbnailViewerH);
    _initializeVideoController().then((value) {
      if(mounted)setState(() {
        thumbnailWidget = ThumbnailViewer(
          videoFile: _videoFile,
          videoDuration: _videoDuration,
          thumbnailHeight: _thumbnailViewerH,
          numberOfThumbnails: widget.numberOfThumbNail,
          width: widget.viewerWidthMinusPadding,
          quality: widget.thumbnailQuality,
        );

        //Must be called because otherwise the controller keeps stuck and only switches between end and start point
        _animationController.reset();
      });
    });

    // Defining the tween points
    _linearTween = Tween(begin: _startPos.dx, end: _endPos.dx);

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (_videoEndPos - _videoStartPos).toInt()),
    );

    _scrubberAnimation = _linearTween.animate(_animationController)
      ..addListener(() {
        if(mounted)setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _animationController.stop();
        }
      });
  }

  @override
  void dispose() {
    if (_videoFile != null) {
      betterPlayerController.setVolume(0.0);
      betterPlayerController.pause();
      betterPlayerController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: widget.key,
      onHorizontalDragStart: _onHorizontalDragStart,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          widget.showDuration
              ? Container(
                  width: _thumbnailViewerW,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        Text(Duration(milliseconds: _videoStartPos.toInt()).toString().split('.')[0],
                            style: widget.durationTextStyle),
                        Text(
                            Duration(milliseconds: _videoEndPos.toInt() - _videoStartPos.toInt())
                                .toString()
                                .split('.')[0],
                            style: widget.durationTextStyle),
                        Text(
                          Duration(milliseconds: _videoEndPos.toInt()).toString().split('.')[0],
                          style: widget.durationTextStyle,
                        ),
                      ],
                    ),
                  ),
                )
              : Container(),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CustomPaint(
              foregroundPainter: TrimEditorPainter(
                  borderRadius: 10,
                  startPos: _startPos,
                  endPos: _endPos,
                  scrubberAnimationDx: _scrubberAnimation.value,
                  circleSize: _circleSize,
                  circlePaintColor: widget.circlePaintColor,
                  borderPaintColor: widget.borderPaintColor,
                  scrubberPaintColor: widget.scrubberPaintColor,
                  betterPlayerController: betterPlayerController),
              child: Container(
                color: Colors.grey[900],
                height: _thumbnailViewerH,
                width: _thumbnailViewerW,
                child: thumbnailWidget == null ? Column() : thumbnailWidget,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeVideoController() async {
    if (_videoFile != null&&betterPlayerController.videoPlayerController!=null) {
      await betterPlayerController.setVolume(1.0);
      _videoDuration = betterPlayerController.videoPlayerController!.value.duration?.inMilliseconds??0;

      _videoEndPos = _videoDuration.toDouble();
      if (widget.onChangeEnd != null) widget.onChangeEnd!(_videoEndPos);

      betterPlayerController.addEventsListener((_) {
        if(betterPlayerController.videoPlayerController==null)return;
        final bool isPlaying = betterPlayerController.videoPlayerController!.value.isPlaying;

        if (isPlaying) {
          if (widget.onChangePlaybackState != null) widget.onChangePlaybackState!(true);
          if (mounted)
            setState(() {
              _currentPosition = betterPlayerController.videoPlayerController!.value.position.inMilliseconds;

              if (_currentPosition > _videoEndPos.toInt()) {
                if (widget.onChangePlaybackState != null) widget.onChangePlaybackState!(false);
                betterPlayerController.pause();
                _animationController.stop();
              } else {
                if (!_animationController.isAnimating) {
                  if (widget.onChangePlaybackState != null) widget.onChangePlaybackState!(true);
                  _animationController.forward();
                }
              }
            });
        } else {
          if (betterPlayerController.videoPlayerController!.value.initialized) {
              if ((_scrubberAnimation.value).toInt() == (_endPos.dx).toInt()) {
                _animationController.reset();
              }
              _animationController.stop();
          }
        }
      });
    }
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    _circleSize = widget.circleSizeOnDrag;

    if (_endPos.dx >= _startPos.dx) {
      _isLeftDrag = false;
      if (_canUpdateStart && _startPos.dx + details.delta.dx > 0) {
        _isLeftDrag = false; // To prevent from scrolling over
        _setVideoStartPosition(details);
      } else if (!_canUpdateStart && _endPos.dx + details.delta.dx < _thumbnailViewerW) {
        _isLeftDrag = true; // To prevent from scrolling over
        _setVideoEndPosition(details);
      }
    } else {
      if (_isLeftDrag && _startPos.dx + details.delta.dx > 0) {
        _setVideoStartPosition(details);
      } else if (!_isLeftDrag && _endPos.dx + details.delta.dx < _thumbnailViewerW) {
        _setVideoEndPosition(details);
      }
    }
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    if (_endPos.dx >= _startPos.dx) {
      if ((_startPos.dx - details.localPosition.dx).abs() > (_endPos.dx - details.localPosition.dx).abs()) {
        if(mounted)setState(() {
          _canUpdateStart = false;
        });
      } else {
        if(mounted)setState(() {
          _canUpdateStart = true;
        });
      }
    } else {
      if (_startPos.dx > details.localPosition.dx) {
        _isLeftDrag = true;
      } else {
        _isLeftDrag = false;
      }
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if(mounted)setState(() {
      _circleSize = widget.circleSize;
    });
  }

  void _setVideoStartPosition(DragUpdateDetails details) async {
    if (!(_startPos.dx + details.delta.dx < 0) &&
        !(_startPos.dx + details.delta.dx > _thumbnailViewerW) &&
        !(_startPos.dx + details.delta.dx > _endPos.dx)) {
      if(mounted)setState(() {
        _startPos += details.delta;
        _startFraction = (_startPos.dx / _thumbnailViewerW);
        print("START PERCENT: $_startFraction");
        _videoStartPos = _videoDuration * _startFraction;
        if (widget.onChangeStart != null) widget.onChangeStart!(_videoStartPos);
      });
      await betterPlayerController.pause();
      await betterPlayerController.seekTo(Duration(milliseconds: _videoStartPos.toInt()));
      _linearTween.begin = _startPos.dx;
      _animationController.duration = Duration(milliseconds: (_videoEndPos - _videoStartPos).toInt());
      _animationController.reset();
    }
  }

  void _setVideoEndPosition(DragUpdateDetails details) async {
    if (!(_endPos.dx + details.delta.dx > _thumbnailViewerW) &&
        !(_endPos.dx + details.delta.dx < 0) &&
        !(_endPos.dx + details.delta.dx < _startPos.dx)) {
      if(mounted)setState(() {
        _endPos += details.delta;
        _endFraction = _endPos.dx / _thumbnailViewerW;
        print("END PERCENT: $_endFraction");
        _videoEndPos = _videoDuration * _endFraction;
        if (widget.onChangeEnd != null) widget.onChangeEnd!(_videoEndPos);
      });
      await betterPlayerController.pause();
      await betterPlayerController.seekTo(Duration(milliseconds: _videoEndPos.toInt()));
      _linearTween.end = _endPos.dx;
      _animationController.duration = Duration(milliseconds: (_videoEndPos - _videoStartPos).toInt());
      _animationController.reset();
    }
  }
}
