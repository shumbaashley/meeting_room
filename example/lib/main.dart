import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ion_flutter_example/views/create_meeting.dart';
import 'package:ion_flutter_example/views/join_meeting.dart';

import 'views/pubsub_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(GetMaterialApp(home: Home(), debugShowCheckedModeBanner: false));
}

class Home extends StatelessWidget {
  @override
  Widget build(context) => Scaffold(
      appBar: AppBar(title: Text('Meeting Room')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
              padding: EdgeInsets.only(top: 15.0, bottom: 15.0),
              child: Row(children: <Widget>[
                Container(
                  width: 300.0,
                ),
                Expanded(
                    child: RaisedButton(
                        child: Text('Create Meeting'),
                        padding: EdgeInsets.all(15.0),
                        color: Colors.blue,
                        textColor: Colors.white,
                        onPressed: () {
                          Get.to(CreateMeeting(),
                              transition: Transition.rightToLeft);
                        })),
                Container(
                  width: 150.0,
                ),
                Expanded(
                    child: RaisedButton(
                        child: Text('Join Room'),
                        padding: EdgeInsets.all(15.0),
                        color: Colors.green,
                        textColor: Colors.white,
                        onPressed: () {
                          Get.to(JoinMeeting(),
                              transition: Transition.rightToLeft);
                        })),
                Container(
                  width: 300.0,
                ),
              ]))
        ],
      ));
}
