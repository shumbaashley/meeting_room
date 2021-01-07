import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_ion/flutter_ion.dart' as ion;

class Participant {
  Participant(this.title, this.renderer, this.stream, this.room);
  MediaStream stream;
  String title;
  String room;
  RTCVideoRenderer renderer;
}

class PubSubController extends GetxController {
  List<Participant> plist = <Participant>[].obs;

  @override
  @mustCallSuper
  void onInit() {
    super.onInit();
  }

  final ion.Signal _signal = ion.JsonRPCSignal('https://conf.ai.co.zw/');
  ion.Client _client;
  ion.LocalStream _localStream;

  void pubsub(String sessionID) async {
    if (_client == null) {
      _client = await ion.Client.create(sid: sessionID, signal: _signal);
      _localStream = await ion.LocalStream.getUserMedia(
          constraints: ion.Constraints.defaults..simulcast = false);
      await _client.publish(_localStream);

      _client.ontrack = (track, ion.RemoteStream remoteStream) async {
        if (track.kind == 'video') {
          print('ontrack: remote stream => ${remoteStream.id}');
          var renderer = RTCVideoRenderer();
          await renderer.initialize();
          renderer.srcObject = remoteStream.stream;
          plist.add(
              Participant('Remote', renderer, remoteStream.stream, sessionID));
        }
      };

      var renderer = RTCVideoRenderer();
      await renderer.initialize();
      renderer.srcObject = _localStream.stream;
      plist.add(Participant('Local', renderer, _localStream.stream, sessionID));
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

class PubSubTestView extends StatefulWidget {
  @override
  _PubSubTestViewState createState() => _PubSubTestViewState();
}

class _PubSubTestViewState extends State<PubSubTestView> {
  final PubSubController c = Get.put(PubSubController());

  TextEditingController meeting_room = TextEditingController();

  bool _started = false;

  Widget getItemView(Participant item) {
    return Container(
        padding: EdgeInsets.all(10.0),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${item.title}:\n${item.stream.id}@${item.room}',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ),
            Expanded(
              child: RTCVideoView(item.renderer,
                  objectFit:
                      RTCVideoViewObjectFit.RTCVideoViewObjectFitContain),
            ),
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Meeting Room Test')),
        body: !_started
            ? Center(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                    SizedBox(height: 30.0),
                    Container(
                      padding: EdgeInsets.all(10),
                      child: Center(
                        child: TextField(
                            controller: meeting_room,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Enter the Meeting Room ID',
                            )),
                      ),
                    ),
                    RaisedButton(
                        child: Text('Join Room'),
                        onPressed: () {
                          c.pubsub(meeting_room.text);
                          setState(() {
                            _started = !_started;
                            meeting_room.text = '';
                          });
                        }),
                  ]))
            : Container(
                padding: EdgeInsets.all(10.0),
                child: Obx(() => GridView.builder(
                    shrinkWrap: true,
                    itemCount: c.plist.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 5.0,
                        crossAxisSpacing: 5.0,
                        childAspectRatio: 1.0),
                    itemBuilder: (BuildContext context, int index) {
                      return getItemView(c.plist[index]);
                    }))),
        floatingActionButton: FloatingActionButton(
            child: Icon(Icons.video_call),
            onPressed: () {
              c.pubsub(meeting_room.text);
              setState(() {
                _started = !_started;
                meeting_room.text = '';
              });
            }));
  }
}
