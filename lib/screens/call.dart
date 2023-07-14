import 'package:agora/utils/utils.dart';
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:agora_rtc_engine/rtc_local_view.dart' as rtc_local_view;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as rtc_remote_view;

class CallPage extends StatefulWidget {
  CallPage({super.key, required this.channelname, required this.role});
  String channelname;
  var role;
  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  List _users = [];
  final _infoStrings = <String>[];
  bool muted = false;
  bool viewpanel = false;
  late RtcEngine _engine;
  @override
  void initState() {
    inintialz();
    super.initState();
  }

  @override
  void dispose() {
    _users.clear();
    _engine.leaveChannel();
    _engine.destroy();
    super.dispose();
  }

  Future<void> inintialz() async {
    if (MyUtils.appId.isEmpty) {
      setState(() {
        _infoStrings.add(
            "App_Id missing, please provide your app idin settings.dart");
      });
      _infoStrings.add("Agora engine is not starting");
    }

    _engine = await RtcEngine.create(MyUtils.appId);
    await _engine.enableVideo();
    await _engine.setChannelProfile(ChannelProfile.LiveBroadcasting);
    await _engine.setClientRole(widget.role);

    VideoEncoderConfiguration configuration = VideoEncoderConfiguration();
    configuration.dimensions = VideoDimensions(width: 1920, height: 1080);
    await _engine.setVideoEncoderConfiguration(configuration);
    _engine.joinChannel(MyUtils.token, widget.channelname, null, 0);
  }

  void _addAgoraEventHandlers() {
    _engine.setEventHandler(
      RtcEngineEventHandler(
        error: (code) {
          setState(() {
            final info = "Error: $code";
            _infoStrings.add(info);
          });
        },
        joinChannelSuccess: (channel, uid, elapsed) {
          setState(
            () {
              final info = 'Join Channel:$channel, uid:$uid';
              _infoStrings.add(info);
            },
          );
        },
        leaveChannel: (stats) {
          setState(
            () {
              _infoStrings.add("Leave Channel");
              _users.clear();
            },
          );
        },
        userJoined: (uid, elapsed) {
          setState(
            () {
              final info = 'User Joined:$uid';
              _infoStrings.add(info);
              _users.add(uid);
            },
          );
        },
        userOffline: (uid, elapsed) {
          setState(() {
            final info = "User offline:$uid";
            _infoStrings.add(info);
            _users.remove(uid);
          });
        },
        firstRemoteVideoFrame: (uid, width, height, elapsed) {
          setState(() {
            final info = "First Remote video: $uid, ${width}x,$height";
            _infoStrings.add(info);
          });
        },
      ),
    );
  }

  Widget _viewRows() {
    final List<StatefulWidget> list = [];
    if (widget.role == ClientRole.Broadcaster) {
      list.add(const rtc_local_view.SurfaceView());
    }
    for (var element in _users) {
      list.add(rtc_remote_view.SurfaceView(
        uid: element,
        channelId: widget.channelname,
      ));
    }
    final views = list;
    return Column(
      children: List.generate(
        views.length,
        (index) => Expanded(child: views[index]),
      ),
    );
  }

  Widget _toolBar() {
    if (widget.role == ClientRole.Audience) return const SizedBox();
    return Container(
      alignment: Alignment.bottomCenter,
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RawMaterialButton(
            onPressed: () {
              setState(() {
                muted = !muted;
              });
              _engine.muteLocalAudioStream(muted);
            },
            child: Icon(
              muted ? Icons.mic_off : Icons.mic,
              color: muted ? Colors.white : Colors.blueAccent,
              size: 20.0,
            ),
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: muted ? Colors.blueAccent : Colors.white,
          ),
          RawMaterialButton(
            onPressed: () => Navigator.pop(context),
            child: const Icon(
              Icons.call_end,
              color: Colors.white,
              size: 35.0,
            ),
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.redAccent,
            padding: EdgeInsets.all(15.0),
          ),
          RawMaterialButton(
            onPressed: () async {
              await _engine.switchCamera();
            },
            child: Icon(
              Icons.switch_camera,
              color: Colors.blueAccent,
              size: 20.0,
            ),
            shape: CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.white,
            padding: EdgeInsets.all(12.0),
          )
        ],
      ),
    );
  }

  Widget _panel() {
    return Visibility(
      visible: viewpanel,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 48),
        alignment: Alignment.bottomCenter,
        child: FractionallySizedBox(
          heightFactor: 0.5,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 48),
            child: ListView.builder(
              reverse: true,
              itemCount: _infoStrings.length,
              itemBuilder: (context, index) {
                if (_infoStrings.isEmpty) {
                  return const Text("null");
                }
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 3, horizontal: 10),
                  child: Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 2, horizontal: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            _infoStrings[index],
                            style: TextStyle(color: Colors.blueGrey),
                          ),
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.greenAccent,
        title: Text("Call"),
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: () {
                setState(() {
                  viewpanel = !viewpanel;
                });
              },
              icon: Icon(Icons.info_outline)),
        ],
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: Stack(
          children: [
            _viewRows(),
            _panel(),
            _toolBar(),
          ],
        ),
      ),
    );
  }
}
