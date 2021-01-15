import 'package:flutter/material.dart';
import 'package:ion_flutter_example/views/meeting_room.dart';
import 'package:ion_flutter_example/views/pubsub_view.dart';
import 'dart:math';

final _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
final Random _rnd = Random();

String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
    length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

//

class CreateMeeting extends StatefulWidget {
  CreateMeeting({Key key}) : super(key: key);

  @override
  _CreateMeetingState createState() => _CreateMeetingState();
}

class _CreateMeetingState extends State<CreateMeeting> {
  String _meetingRoom;

  @override
  void initState() {
    super.initState();
    _meetingRoom = getRandomString(10);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Create Meeting Room'),
        ),
        body: Center(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
              Container(
                padding: const EdgeInsets.fromLTRB(30.0, 30.0, 30.0, 150.0),
                child: Text(
                  'Your meeting room ID is: $_meetingRoom',
                  style: const TextStyle(
                    fontSize: 32.0,
                    color: Colors.black,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              RaisedButton(
                  child: Text('Start Meeting'),
                  padding: EdgeInsets.all(15.0),
                  color: Colors.blue,
                  textColor: Colors.white,
                  onPressed: () {
                    //Create a Meeting room
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MeetingRoom(_meetingRoom),
                      ),
                    );
                  }),
            ])));
  }
}
