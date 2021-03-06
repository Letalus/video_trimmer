import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class ThumbnailViewer extends StatelessWidget {
  final videoFile;
  final videoDuration;
  final thumbnailHeight;
  final double width;
  final int numberOfThumbnails;
  final int quality;

  ThumbnailViewer({
    required this.videoFile,
    required this.videoDuration,
    required this.thumbnailHeight,
    required this.numberOfThumbnails,
    required this.width,
    this.quality = 75,
  })  : assert(videoFile != null),
        assert(videoDuration != null),
        assert(thumbnailHeight != null);

  Stream<List<Uint8List?>> generateThumbnail() async* {
    final String _videoPath = videoFile.path;

    double _eachPart = videoDuration / numberOfThumbnails;

    List<Uint8List?> _byteList = [];

    for (int i = 1; i <= numberOfThumbnails; i++) {
      int _timeMs = (_eachPart * i).toInt();
      Uint8List? _bytes;
      _bytes = await VideoThumbnail.thumbnailData(
        video: _videoPath,
        imageFormat: ImageFormat.JPEG,
        timeMs: _timeMs,
        quality: quality,
      );

      _byteList.add(_bytes);

      yield _byteList;
    }
  }

  @override
  Widget build(BuildContext context) {
    double _widthfactor = width/(thumbnailHeight*numberOfThumbnails);
    assert(_widthfactor>0, 'widthfactor must be greater than 0');
    return StreamBuilder<List<Uint8List?>>(
      stream: generateThumbnail(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<Uint8List?> _imageBytes = snapshot.data as List<Uint8List?>;
          return SizedBox(
            width: width,
            height: thumbnailHeight,
            child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _imageBytes.length,
                itemBuilder: (context, index) {
                  return Align(
                    widthFactor: (_widthfactor),
                    child: Container(
                      height: thumbnailHeight,
                      width: thumbnailHeight,
                      child: Builder(
                        builder: (context){
                          try{
                            if(_imageBytes[index]==null){
                              return Container();
                            }
                            return Image(
                              image: MemoryImage(_imageBytes[index]!),
                              fit: BoxFit.cover,
                              alignment: Alignment.center,
                            );
                          }catch (e){
                            return Container();
                          }
                        },
                      ),
                    ),
                  );
                }),
          );
        } else {
          return Container(
            color: Colors.grey[900],
            height: thumbnailHeight,
            width: double.maxFinite,
          );
        }
      },
    );
  }
}
