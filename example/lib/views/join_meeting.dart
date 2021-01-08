import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/routes/transitions_type.dart';
import 'package:ion_flutter_example/views/pubsub_view.dart';

class JoinMeeting extends StatefulWidget {
  JoinMeeting({Key key}) : super(key: key);

  @override
  _JoinMeetingState createState() => _JoinMeetingState();
}

class _JoinMeetingState extends State<JoinMeeting> {
  TextEditingController meeting_room = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Join Room'),
        ),
        body: Center(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
              SizedBox(height: 30.0),
              Form(
                key: _formKey,
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: TextFormField(
                      autofocus: true,
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
                  padding: EdgeInsets.all(15.0),
                  color: Colors.blue,
                  textColor: Colors.white,
                  onPressed: () {
                    if (_formKey.currentState.validate()) {
                      //Join Meeting room
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PubSubTestView(meeting_room.text),
                        ),
                      );
                    }
                  }),
            ])));
  }
}
