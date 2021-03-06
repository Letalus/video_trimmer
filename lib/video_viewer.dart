import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoViewer extends StatelessWidget {
  final Color borderColor;
  final double borderWidth;
  final EdgeInsets padding;
  final VideoPlayerController videoPlayerController;

  /// For showing the video playback area.
  ///
  /// This only contains optional parameters. They are:
  ///
  /// * [borderColor] for specifying the color of the video
  /// viewer area border. By default it is set to `Colors.transparent`.
  ///
  ///
  /// * [borderWidth] for specifying the border width around
  /// the video viewer area. By default it is set to `0.0`.
  ///
  ///
  /// * [padding] for specifying a padding around the video viewer
  /// area. By default it is set to `EdgeInsets.all(0.0)`.
  ///
  VideoViewer(
      this.videoPlayerController,{
    this.borderColor = Colors.transparent,
    this.borderWidth = 0.0,
    this.padding = const EdgeInsets.all(0.0),
  });


  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: padding,
        child: AspectRatio(
          aspectRatio: videoPlayerController.value.aspectRatio,
          child: videoPlayerController.value.isInitialized
              ? Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      width: borderWidth,
                      color: borderColor,
                    ),
                  ),
                  child: VideoPlayer(videoPlayerController),
                )
              : Container(
                  child: Center(
                    child: CircularProgressIndicator(
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
