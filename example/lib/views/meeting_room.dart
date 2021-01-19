import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_ion/flutter_ion.dart' as ion;
import 'package:ion_flutter_example/widgets/video_renderer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';

class Participant {
  Participant(this.displayname, this.title, this.renderer, this.stream);
  MediaStream stream;
  String displayname;
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

  // final ion.Signal _signal = ion.JsonRPCSignal('ws://127.0.0.1:7000/ws');
  final ion.Signal _signal = ion.JsonRPCSignal('wss://pamwe.co.zw:7000/ws');
  ion.Client _client;
  ion.LocalStream _localStream;

  void pubsub(String roomID, String name) async {
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
              .add(Participant(name, 'Remote', renderer, remoteStream.stream));
        }
      };

      var renderer = RTCVideoRenderer();
      await renderer.initialize();
      renderer.srcObject = _localStream.stream;
      // enable speaker on start
      var audioTrack = _localStream.stream.getAudioTracks()[0];
      audioTrack.enableSpeakerphone(true);
      participantList
          .add(Participant(name, 'Local', renderer, _localStream.stream));
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

}

class MeetingRoom extends StatefulWidget {
  final String _room;
  final String _name;
  MeetingRoom(this._room, [this._name]);

  @override
  _MeetingRoomState createState() => _MeetingRoomState(_room, _name);
}

class _MeetingRoomState extends State<MeetingRoom> {
  final MeetingController c = Get.put(MeetingController());
  final _scaffoldkey = GlobalKey<ScaffoldState>();
  List<Participant> participantList = <Participant>[].obs;

  VideoRendererAdapter _localVideo;
  SharedPreferences prefs;

  bool _cameraOff = false;
  bool _microphoneOff = false;
  bool _speakerOn = true;

  final double LOCAL_VIDEO_WIDTH = 120.0;
  final double LOCAL_VIDEO_HEIGHT = 64.0;

  String _displayname;
  final String _room;
  _MeetingRoomState(this._room, [this._displayname]);

  @override
  void initState() {
    super.initState();
    _displayname ??= 'Admin';
    WidgetsBinding.instance.addPostFrameCallback((_) => init());
  }

  init() async {
    c.pubsub(_room, _displayname);
  }

  Widget getItemView(Participant item) {
    print(item.displayname);
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
                      )
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: 48,
                child: Stack(
                  children: <Widget>[
                    Opacity(
                      opacity: 1.0, // TODO  change back
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
                            children: _buildTools(c._localStream),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[],
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
                        // _loginAlert(_room);
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
  List<Widget> _buildTools(ion.LocalStream _stream) {
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
          onPressed: (){
            _turnMicrophone(_stream);
          }
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
    _showSnackBar('Switch camera');
  }

  //Open or close local audio
  void _turnMicrophone(ion.LocalStream _stream) {
        if (_stream != null && _stream.stream.getAudioTracks().isNotEmpty) {
      setState(() {
        _microphoneOff = !_microphoneOff;
      });
      _localVideo.stream.getAudioTracks()[0].enabled = !_microphoneOff;;

      if (_microphoneOff) {
        _showSnackBar('The microphone is muted');
      } else {
        _showSnackBar('The microphone is unmuted');
      }
    } else {}
  }

  //Leave current video room
  void _hangUp() {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
                title: Text('Hangup'),
                content: Text('Are you sure to leave the room?'),
                actions: <Widget>[
                  TextButton(
                    child: Text('Cancel'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: Text(
                      'Hangup',
                      style: TextStyle(color: Colors.red),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      // _cleanUp();
                      _showSnackBar('Call ended');
                    },
                  )
                ]));
  }

  //Switch speaker/earpiece
  void _switchSpeaker() {
    _showSnackBar('Switch speaker');
  }

  //Switch local camera
  void _switchCamera() {
    _showSnackBar('Switch camera');
  }

  // Show snackbar notification
  void _showSnackBar(String message) {
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

  // africom additions
  void _loginAlert(roomID) {
    showDialog<Null>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Login Request'),
          content: Text(
              // 'There is a login request to enter meeting room ($roomID)\nfrom : ${json["senderName"]}'),
              'Login reuest from New User'),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                'Accept',
                style: TextStyle(color: Colors.green),
              ),
              onPressed: () async {
                // var client = widget._helper.client;

                // input information to accept participant
                // client.accepted("roomdev", "uuid");
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

