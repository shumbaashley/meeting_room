import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_ion/flutter_ion.dart' as ion;

class Participant {
  Participant(this.title, this.renderer, this.stream);
  MediaStream stream;
  String title;
  RTCVideoRenderer renderer;
}

class PubSubController extends GetxController {
  List<Participant> plist = <Participant>[].obs;
  String room;

  final _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  final Random _rnd = Random();

  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  //  getRandomString(10);

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
          plist.add(Participant('Remote', renderer, remoteStream.stream));
        }
      };

      var renderer = RTCVideoRenderer();
      await renderer.initialize();
      renderer.srcObject = _localStream.stream;
      plist.add(Participant('Local', renderer, _localStream.stream));
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

  void _leave() async {
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

class PubSubTestView extends StatefulWidget {
  @override
  _PubSubTestViewState createState() => _PubSubTestViewState();
}

class _PubSubTestViewState extends State<PubSubTestView> {
  final PubSubController c = Get.put(PubSubController());
  final _formKey = GlobalKey<FormState>();
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
                '${item.title}:\n${item.stream.id}',
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
                    Form(
                      key: _formKey,
                      child: Padding(
                        padding: EdgeInsets.all(10),
                        child: TextFormField(
                            // ignore: missing_return
                            validator: (String value) {
                              if (value.isEmpty) {
                                return 'Please enter the meeting room id';
                              }
                            },
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
                          if (_formKey.currentState.validate()) {
                            c.pubsub(meeting_room.text);
                            setState(() {
                              _started = !_started;
                              meeting_room.text = '';
                            });
                          }
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
        floatingActionButtonLocation: _started ? FloatingActionButtonLocation.centerFloat : null,
        floatingActionButton:_started ? FloatingActionButton(
            backgroundColor: Colors.red,
            child: Icon(Icons.call_end),
            onPressed: () {
              c.pubsub(meeting_room.text);
              setState(() {
                _started = !_started;
                meeting_room.text = '';
              });
              c._leave();
            }) : null);
  }
}
