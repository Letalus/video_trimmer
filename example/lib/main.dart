import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_trimmer/trim_editor.dart';
import 'package:video_trimmer/video_trimmer.dart';
import 'package:video_trimmer/video_viewer.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Trimmer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Trimmer? _trimmer;

  double _startValue = 0.0;
  double _endValue = 0.0;

  bool _isPlaying = false;
  bool _progressVisibility = false;
  File _videoFile = File('/data/user/0/com.example.example/cache/image_picker1717731443242073867.jpg');

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 0), () async {
      _trimmer = Trimmer(_videoFile);
      await _trimmer!.loadVideo();
      setState(() {});
      Future.delayed(Duration(milliseconds: 300), () {
        setState(() {});
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Video Trimmer"),
      ),
      body: Builder(
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.only(bottom: 30.0),
            color: Colors.black,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                RaisedButton(
                  onPressed: _progressVisibility
                      ? null
                      : () async {
                          Future.delayed(Duration(milliseconds: 200), () {
                            _trimmer?.videoPlayerController.dispose();
                          });

                          setState(() {
                            _trimmer = null;
                          });
                          PickedFile? pickedFile = await ImagePicker().getVideo(
                            source: ImageSource.gallery,
                          );
                          if (pickedFile != null) {
                            _trimmer = Trimmer(File(pickedFile.path));
                            await _trimmer!.loadVideo();
                            setState(() {});
                            Future.delayed(Duration(milliseconds: 300), () {
                              setState(() {});
                            });
                          }
                        },
                  child: Text("Get Other image"),
                ),
                Expanded(
                  child: (_trimmer != null && _trimmer?.videoPlayerController != null)
                      ? VideoViewer(_trimmer!.videoPlayerController)
                      : Container(),
                ),
                _trimmer != null
                    ? Center(
                        child: TrimEditor(
                          _trimmer!,
                          viewerHeight: 70.0,
                          viewerWidthMinusPadding: MediaQuery.of(context).size.width,
                          onChangeStart: (value) {
                            _startValue = value;
                          },
                          onChangeEnd: (value) {
                            _endValue = value;
                          },
                          onChangePlaybackState: (value) {
                            if (mounted) {
                              setState(() {
                                _isPlaying = value;
                              });
                            }
                          },
                        ),
                      )
                    : Container(),
                FlatButton(
                  child: _isPlaying
                      ? Icon(
                          Icons.pause,
                          size: 80.0,
                          color: Colors.white,
                        )
                      : Icon(
                          Icons.play_arrow,
                          size: 80.0,
                          color: Colors.white,
                        ),
                  onPressed: () async {
                    if(_trimmer==null){
                      print('playback cant be activated because the trimmer must no be null');
                      return;
                    }
                    bool playbackState = await _trimmer!.videoPlaybackControl(
                      startValue: _startValue,
                      endValue: _endValue,
                    );
                    setState(() {
                      _isPlaying = playbackState;
                    });
                  },
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
