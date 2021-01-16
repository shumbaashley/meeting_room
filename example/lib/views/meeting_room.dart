import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_ion/flutter_ion.dart' as ion;
import 'package:ion_flutter_example/widgets/video_renderer.dart';

import '../main.dart';

class Participant {
  Participant(this.title, this.renderer, this.stream);
  MediaStream stream;
  String title;
  RTCVideoRenderer renderer;
}

class MeetingController extends GetxController {
  List<Participant> participantList = <Participant>[].obs;

  @override
  @mustCallSuper
  void onInit() {
    super.onInit();
  }

  final ion.Signal _signal = ion.JsonRPCSignal('ws://127.0.0.1:7000/ws');
  ion.Client _client;
  ion.LocalStream _localStream;

  void pubsub(String roomID) async {
    if (_client == null) {
      _client = await ion.Client.create(sid: roomID, signal: _signal);
      _localStream = await ion.LocalStream.getUserMedia(
          constraints: ion.Constraints.defaults..simulcast = false);
      await _client.publish(_localStream);

      _client.ontrack = (track, ion.RemoteStream remoteStream) async {
        if (track.kind == 'video') {
          print('ontrack: remote stream => ${remoteStream.id}');
          var renderer = RTCVideoRenderer();
          await renderer.initialize();
          renderer.srcObject = remoteStream.stream;
          participantList
              .add(Participant('Remote', renderer, remoteStream.stream));
        }
      };

      var renderer = RTCVideoRenderer();
      await renderer.initialize();
      renderer.srcObject = _localStream.stream;
      participantList.add(Participant('Local', renderer, _localStream.stream));
    } else {
      await _localStream.unpublish();
      _localStream.stream.getTracks().forEach((element) {
        element.dispose();
      });
      await _localStream.stream.dispose();
      _localStream = null;
      _client.close();
      _client = null;
    }
  }

  void _closeLocalStream(MeetingController psc) async {
    await psc._localStream.unpublish();
    psc._localStream.stream.getTracks().forEach((element) {
      element.dispose();
    });
    await psc._localStream.stream.dispose();
    psc._localStream = null;
    psc._client.close();
    psc._client = null;
  }
}

class MeetingRoom extends StatefulWidget {
  // SharedPreferences prefs;
  // prefs = await SharedPreferences.getInstance();
  // name = prefs.getString('display_name') ?? 'Administrator';
  final String _room;
  MeetingRoom(this._room);

  @override
  _MeetingRoomState createState() => _MeetingRoomState(_room);
}

class _MeetingRoomState extends State<MeetingRoom> {
  final MeetingController c = Get.put(MeetingController());
  final _scaffoldkey = GlobalKey<ScaffoldState>();
  List<Participant> participantList = <Participant>[].obs;

  VideoRendererAdapter _localVideo;

  bool _cameraOff = false;
  bool _microphoneOff = false;
  bool _speakerOn = true;

  final double LOCAL_VIDEO_WIDTH = 120.0;
  final double LOCAL_VIDEO_HEIGHT = 64.0;

  final String _room;
  _MeetingRoomState(this._room);

  final ion.Signal _signal = ion.JsonRPCSignal('https://pamwe.co.zw:7000/ws');
  ion.Client _client;
  ion.LocalStream _localStream;

  RTCVideoRenderer renderer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => init());
  }

  init() async {
    c.pubsub(_room);
    // if (_client == null) {
    //   _client = await ion.Client.create(sid: _room, signal: _signal);
    //   _localStream = await ion.LocalStream.getUserMedia(
    //       constraints: ion.Constraints.defaults..simulcast = false);
    //   await _client.publish(_localStream);

    //   _client.ontrack = (track, ion.RemoteStream remoteStream) async {
    //     if (track.kind == 'video') {
    //       print('ontrack: remote stream => ${remoteStream.id}');
    //       renderer = RTCVideoRenderer();
    //       await renderer.initialize();
    //       renderer.srcObject = remoteStream.stream;
    //       participantList
    //           .add(Participant('Remote', renderer, remoteStream.stream));
    //     }
    //   };

    //   renderer = RTCVideoRenderer();
    //   await renderer.initialize();
    //   renderer.srcObject = _localStream.stream;
    //   participantList.add(Participant('Local', renderer, _localStream.stream));
    // } else {
    //   await _localStream.unpublish();
    //   _localStream.stream.getTracks().forEach((element) {
    //     element.dispose();
    //   });
    //   await _localStream.stream.dispose();
    //   _localStream = null;
    //   _client.close();
    //   _client = null;
    // }
  }

  void _closeLocalStream() async {
    await _localStream.unpublish();
    _localStream.stream.getTracks().forEach((element) {
      element.dispose();
    });
    await _localStream.stream.dispose();
    _localStream = null;
    _client.close();
    _client = null;
  }

  Widget getItemView(Participant item) {
    return Container(
        padding: EdgeInsets.all(10.0),
        child: Column(
          children: [
            Expanded(
              child: RTCVideoView(item.renderer,
                  objectFit:
                      RTCVideoViewObjectFit.RTCVideoViewObjectFitContain),
            ),
          ],
        ));
  }

  Widget getSingleVideo(RTCVideoRenderer item) {
    return Container(
        padding: EdgeInsets.all(10.0),
        child: Column(
          children: [
            Expanded(
              child: RTCVideoView(item,
                  objectFit:
                      RTCVideoViewObjectFit.RTCVideoViewObjectFitContain),
            ),
          ],
        ));
  }

  Widget _buildLocalVideo(Orientation orientation) {
    if (_localStream != null) {
      return SizedBox(
          width: (orientation == Orientation.portrait)
              ? LOCAL_VIDEO_HEIGHT
              : LOCAL_VIDEO_WIDTH,
          height: (orientation == Orientation.portrait)
              ? LOCAL_VIDEO_WIDTH
              : LOCAL_VIDEO_HEIGHT,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black87,
              border: Border.all(
                color: Colors.white,
                width: 0.5,
              ),
            ),
            child: GestureDetector(
                // onTap: () {
                //   _switchCamera();
                // },
                // onDoubleTap: () {
                //   _localVideo.switchObjFit();
                // },
                child: RTCVideoView(renderer)),
          ));
    }
    return Container();
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(builder: (context, orientation) {
      return SafeArea(
          child: Scaffold(
        key: _scaffoldkey,
        body: Container(
          color: Colors.white,
          child: Stack(
            children: <Widget>[
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  color: Colors.black87,
                  child: Stack(
                    children: <Widget>[
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: Container(
                            padding: EdgeInsets.all(10.0),
                            child: Obx(() => GridView.builder(
                                shrinkWrap: true,
                                itemCount: c.participantList.length,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        mainAxisSpacing: 5.0,
                                        crossAxisSpacing: 5.0,
                                        childAspectRatio: 1.0),
                                itemBuilder: (BuildContext context, int index) {
                                  return getItemView(c.participantList[index]);
                                }))),
                      ),
                      Positioned(
                        right: 10,
                        top: 48,
                        child: Container(
                            // child: participantList != null ? getItemView(participantList[0]): Container(),
                            // child: _buildLocalVideo(orientation),
                            ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 48,
                        height: 90,
                        child: Container(
                          margin: EdgeInsets.all(6.0),
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            // children: //_buildVideoViews(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // (_remoteVideos.length == 0) ? _buildLoading() : Container(),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: 48,
                child: Stack(
                  children: <Widget>[
                    Opacity(
                      opacity: 1.0, // TODO ::: change back
                      child: Container(
                        color: Colors.blue,
                      ),
                    ),
                    Container(
                      child: Center(
                        child: Container(
                          margin: EdgeInsets.fromLTRB(10, 10, 0, 10),
                          height: 48,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: _buildTools(),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                          child: SizedBox(
                            height: 48,
                            width: 56,
                            child: Image.asset(
                              'assets/images/africom.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 48,
                child: Stack(
                  children: <Widget>[
                    Opacity(
                      opacity: 0.5,
                      child: Container(
                        color: Colors.lightBlue,
                      ),
                    ),
                    // Chat message
                    IconButton(
                      icon: Icon(
                        Icons.chat_bubble_outline,
                        size: 28.0,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(
                        //     builder: (context) => ChatPage(
                        //         widget._helper.client,
                        //         this._messages,
                        //         this.name,
                        //         this.room),
                        //   ),
                        // );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ));
    });
  }

  //tools
  List<Widget> _buildTools() {
    return <Widget>[
      SizedBox(
        width: 48,
        height: 48,
        child: RawMaterialButton(
          child: _cameraOff
              ? Icon(Icons.videocam_off, color: Colors.red)
              : Icon(
                  Icons.video_call,
                  color: Colors.white,
                ),
          onPressed: _turnCamera,
        ),
      ),
      SizedBox(
        width: 48,
        height: 48,
        child: RawMaterialButton(
          child: _microphoneOff
              ? Icon(Icons.mic_off, color: Colors.red)
              : Icon(
                  Icons.mic,
                  color: Colors.white,
                ),
          onPressed: _turnMicrophone,
        ),
      ),
      SizedBox(
        width: 48,
        height: 48,
        child: RawMaterialButton(
          child: Icon(Icons.call_end, color: Colors.red),
          onPressed: _hangUp,
        ),
      ),
      SizedBox(
        width: 48,
        height: 48,
        child: RawMaterialButton(
          child: Icon(Icons.computer, color: Colors.white),
          onPressed: _switchSpeaker,
        ),
      ),
      SizedBox(
        width: 48,
        height: 48,
        child: RawMaterialButton(
          child: Icon(
            Icons.format_list_bulleted,
            color: Colors.white,
            semanticLabel: 'Options',
          ),
          onPressed: _switchCamera,
        ),
      ),
    ];
  }

  // _showSnackBar(context, 'Note successfully deleted');

  //Open or close local video
  void _turnCamera() {
    _showSnackBar(':::Switch camera:::');
  }

  //Open or close local audio
  void _turnMicrophone() {
    _showSnackBar(':::Switch audio:::');
  }

  //Leave current video room
  void _hangUp() {
    _closeLocalStream();
    _showSnackBar(':::Call ended:::');
  }

  //Switch speaker/earpiece
  void _switchSpeaker() {
    _showSnackBar(':::Switch speaker:::');
  }

  //Switch local camera
  void _switchCamera() {
    _showSnackBar(':::Switch camera:::');
  }

  // Show snackbar notification
  _showSnackBar(String message) {
    final snackBar = SnackBar(
      content: Text(
        message,
        style: TextStyle(color: Colors.white),
      ),
      duration: Duration(
        milliseconds: 1000,
      ),
    );
    _scaffoldkey.currentState.showSnackBar(snackBar);
  }
}

// Column(mainAxisAlignment: MainAxisAlignment.end, children: [
//                 Container(
//                     padding: EdgeInsets.all(10.0),
//                     child: Obx(() => GridView.builder(
//                         shrinkWrap: true,
//                         itemCount: c.participantList.length,
//                         gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                             crossAxisCount: 3,
//                             mainAxisSpacing: 5.0,
//                             crossAxisSpacing: 5.0,
//                             childAspectRatio: 1.0),
//                         itemBuilder: (BuildContext context, int index) {
//                           return getItemView(c.participantList[index]);
//                         }))),
//                 Container(
//                   color: Colors.black,
//                   child: Center(
//                     child: Container(
//                       margin: EdgeInsets.fromLTRB(10, 10, 0, 10),
//                       height: 60,
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         crossAxisAlignment: CrossAxisAlignment.center,
//                         children: _buildTools(),
//                       ),
//                     ),
//                   ),
//                 ),
//               ])
// floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
// floatingActionButton: FloatingActionButton(
// backgroundColor: Colors.red,
// child: Icon(Icons.call_end),
// onPressed: () async {
// _closeRemoteStream(c);
// c._closeLocalStream(c);
// c.pubsub(_room);
// Navigator.push(
//   context,
//   MaterialPageRoute(
//     builder: (context) => Home(),
//   ),
// );
// })
