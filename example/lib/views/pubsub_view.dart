import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_ion/flutter_ion.dart' as ion;

import '../main.dart';

class Participant {
  Participant(this.title, this.renderer, this.stream);
  MediaStream stream;
  String title;
  RTCVideoRenderer renderer;
}

class PubSubController extends GetxController {
  List<Participant> plist = <Participant>[].obs;

  @override
  @mustCallSuper
  void onInit() {
    super.onInit();
  }

  final ion.Signal _signal = ion.JsonRPCSignal('https://andromeda.ai.co.zw/');
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
}

class PubSubTestView extends StatefulWidget {
  final String _room;
  PubSubTestView(this._room);

  @override
  _PubSubTestViewState createState() => _PubSubTestViewState(_room);
}

class _PubSubTestViewState extends State<PubSubTestView> {
  final PubSubController c = Get.put(PubSubController());

  final String _room;
  _PubSubTestViewState(this._room);

  @override
  void initState() {
    super.initState();
    c.pubsub(_room);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Meeting Room : $_room')),
        body: Container(
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
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.red,
            child: Icon(Icons.call_end),
            onPressed: () async {
              await c._localStream.unpublish();
              c._localStream.stream.getTracks().forEach((element) {
                element.dispose();
              });
              await c._localStream.stream.dispose();
              c._localStream = null;
              c._client.close();
              c._client = null;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Home(),
                ),
              );
            }));
  }
}
